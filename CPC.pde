class CPC {
  D7 diskette;
  //  RAM ram;
  //  ROM rom;
  Z80 z80;
  GateArray ga;
  Firmware fwv;
  PSG psg;
  Memory mem;

  int iter = 0;
  int iterMax = -1; //2000000;
  int speed;
  boolean stepForward;
  boolean freerun;

  CPC () {
    this.stepForward = false;
    this.freerun = false;

    this.fwv = new Firmware();
    this.mem = new Memory();
    this.z80 = new Z80();
    this.ga = new GateArray();
    this.psg = new PSG();
    this.diskette = new D7("HEADOVER.DSK");

    // set References
    this.z80.setRef(this.mem, this.fwv, this.ga, this.psg);
    this.fwv.setRef(this.z80, this.ga, this.mem, this.diskette);
    this.ga.setRef(this.z80, this.mem, this.fwv);
    this.mem.setRef(this.fwv);
    this.psg.setRef(this.z80);

    this.mem.RETVectors();
    this.mem.bootUpMem();
    this.z80.initPC(0);

    //this.diskette.readFile();
    this.diskette.loadFile("HEADOVER.BIN", this.mem);
    //this.diskette.loadFile("HEADOVER.I", this.ram, 0x4000);
    //this.diskette.loadFile("HEADOVER.II", this.ram, 0xc000);
    //this.diskette.loadFile("HEADOVER.III", this.ram);
    
    this.mem.romDump();
  }

  void setReg(int b, int c, int d, int e, int h, int l, int a, int f) {
    this.z80.reg.reg8b[this.z80.reg.Bpos] = b;
    this.z80.reg.reg8b[this.z80.reg.Cpos] = c;
    this.z80.reg.reg8b[this.z80.reg.Dpos] = d;
    this.z80.reg.reg8b[this.z80.reg.Epos] = e;
    this.z80.reg.reg8b[this.z80.reg.Hpos] = h;
    this.z80.reg.reg8b[this.z80.reg.Lpos] = l;
    this.z80.reg.reg8b[this.z80.reg.Apos] = a;
    this.z80.reg.reg8b[this.z80.reg.Fpos] = f;
  }

  void setPC (int pc) {
    this.z80.reg.setPC(pc & 0xFFFF);
  }

  void setSpeed (int sp) {
    this.speed = (sp < 1) ? 1 : sp;
  }


  void setBKP (int breakpoint) {
    this.z80.reg.setBKP(breakpoint & 0xFFFF);
    this.z80.reg.setBKPOn();
  }

  void setBKPOff () {
    this.z80.reg.setBKPOff();
  }

  void setSP (int sp) {
    this.z80.reg.setSP(sp & 0xFFFF);
  }

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
    this.stepForward = true;
    this.z80.reg.setBKPOff();
    this.run();
  }

  void hideDebugWindow () {
    this.ga.hideDebugWindow();
  }

  void run () {
    for (int sp = 0; sp < this.speed; sp ++) {
      if ((this.iterMax > 0) && (this.iter == this.iterMax)) {
        println("Reached max iter");
        this.halt();
        noLoop();
        break;
      }
      if ((this.iter % 20) == 0) {
        this.ga.display();
      }
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