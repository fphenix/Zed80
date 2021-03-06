class CPC {
  D7 diskette;
  //  RAM ram;
  //  ROM rom;
  Keyboard kb;
  Z80 z80;
  GateArray ga;
  Firmware fwv;
  PSG psg;
  Memory mem;
  Pinout pin;
  Floppy fdc;

  int iter = 0;
  int iterMax = -1; //2000000;
  int speed;
  boolean stepForward;
  boolean freerun;

  CPC (PApplet top) {
    this.init(top);
  }

  void init (PApplet top) {
    this.stepForward = false;
    this.freerun = false;

    this.fwv = new Firmware();
    this.mem = new Memory();
    this.z80 = new Z80();
    this.ga = new GateArray();
    this.psg = new PSG(top);
    this.kb = new Keyboard();
    this.pin = new Pinout();
    this.fdc = new Floppy();

    // set References
    this.z80.setRef(this.mem, this.fwv, this.pin);
    this.fwv.setRef(this.z80, this.ga, this.mem, this.diskette);
    this.ga.setRef(this.z80, this.mem, this.fwv, this.psg);
    this.mem.setRef(this.fwv);
    this.psg.setRef(this.z80);
    this.pin.setRef(this.mem, this.ga, this.psg, this.fdc);
    this.kb.setRef(this.z80.pin, this.psg);

    this.mem.bootUpMem();
    this.mem.RETVectors();
    this.z80.initPC(0);
  }

  //------------------------------------------------------------------------
  void setPC (int pc) {
    this.z80.reg.setPC(pc & 0xFFFF);
  }

  void setSP (int sp) {
    this.z80.reg.setSP(sp & 0xFFFF);
  }

  void setRegs (int a, int b, int c, int d, int e, int h, int l, int f) {
    this.z80.reg.reg8b[this.z80.reg.Bpos] = b;
    this.z80.reg.reg8b[this.z80.reg.Cpos] = c;
    this.z80.reg.reg8b[this.z80.reg.Dpos] = d;
    this.z80.reg.reg8b[this.z80.reg.Epos] = e;
    this.z80.reg.reg8b[this.z80.reg.Hpos] = h;
    this.z80.reg.reg8b[this.z80.reg.Lpos] = l;
    this.z80.reg.reg8b[this.z80.reg.Apos] = a;
    this.z80.reg.reg8b[this.z80.reg.Fpos] = f;
  }

  void setSpeRegs (int i, int r, int ix, int iy) {
    this.z80.reg.reg8b[this.z80.reg.Ipos] = i;
    this.z80.reg.reg8b[this.z80.reg.Rpos] = r;
    this.z80.reg.reg16b[this.z80.reg.IXpos] = ix;
    this.z80.reg.reg16b[this.z80.reg.IYpos] = iy;
  }

  void setPrimes (int a, int b, int c, int d, int e, int h, int l, int f) {
    this.z80.reg.regPrime[this.z80.reg.Bpos] = b;
    this.z80.reg.regPrime[this.z80.reg.Cpos] = c;
    this.z80.reg.regPrime[this.z80.reg.Dpos] = d;
    this.z80.reg.regPrime[this.z80.reg.Epos] = e;
    this.z80.reg.regPrime[this.z80.reg.Hpos] = h;
    this.z80.reg.regPrime[this.z80.reg.Lpos] = l;
    this.z80.reg.regPrime[this.z80.reg.Apos] = a;
    this.z80.reg.regPrime[this.z80.reg.Fpos] = f;
  }

  //----------------------------------------------------------------
  void setSpeed (int tspeed) {
    this.speed = (tspeed < 1) ? 1 : tspeed;
  }

  void setDebugRefresh(int df) {
    this.ga.setDbgRefresh(df);
  }

  void setShowingDebugMem (int m) {
    this.ga.dbg.setShowingMem(m);
  }

  void setBKP (int breakpoint) {
    this.z80.reg.setBKP(breakpoint & 0xFFFF);
    this.z80.reg.setBKPOn();
  }

  void setBKPOff () {
    this.z80.reg.setBKPOff();
  }

  //-----------------------------------------------------------------
  void attachFloppyDisc (String d7name) {
    this.fdc.readFloppy(d7name);
  }

  //-----------------------------------------------------------------
  void turnon () {
    this.z80.go();
  }

  void halt () {
    this.z80.halt();
    this.freerun = false;
  }

  void go() {
    loop();
    this.freerun = true;
    this.run();
  }

  void step() {
    loop();
    this.freerun = false;
    this.stepForward = true;
    this.z80.reg.setBKPOff();
    this.run();
  }

  void hideDebugWindow () {
    this.ga.hideDebugWindow();
  }

  void run () {
    for (int sp = 0; sp < this.speed; sp ++) {
      if ((this.iterMax > 0) && (this.iter >= this.iterMax)) {
        println("Reached max iter");
        this.halt();
        noLoop();
        break;
      }
      this.ga.display();
      this.fdc.motorSpin();
      if ((this.z80.reg.breakMode) && (this.z80.reg.breakPoint == this.z80.pc)) {
        println("Break Point at 0x" + hex(this.z80.pc, 4));
        this.mem.memDump();
        this.halt();
        noLoop();
        break;
      } else if (this.stepForward || this.freerun) {
        this.z80.step();
        this.ga.setInstr(this.z80.opcode.instr.asmInstr);
        this.iter++;
        this.stepForward = false;
      }
    }
  }
}