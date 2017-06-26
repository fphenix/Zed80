class DebugWindow {

  int debugLine;
  boolean showDebug;
  float xdebug;
  int debugMem;
  int regxpad = 55;
  int regypad = 16;

  GateArray ga; // ref
  PSG psg; // ref

  DebugWindow (boolean shw) {
    this.showDebug = shw;
    this.debugLine = 0;
    this.debugMem = 0x4000;
  }

  void setRef(GateArray garef, PSG psgref) {
    this.ga = garef;
    this.psg = psgref;
  }

  void setShowingMem (int m) {
    this.debugMem = m & 0xFFFF;
  }

  void showDebugRegs() {
    // Debug lines : 16b registers (BC, DE, HL, IR and AF)
    fill(255, 255, 0);
    this.debugLine++;
    for (int i = 0; i <= this.ga.reg.HLpos; i++) {
      text(this.ga.reg.reg16Name[i], (i*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    }
    text(this.ga.reg.reg16Name[this.ga.reg.IRpos], (3*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.reg.reg16Name[this.ga.reg.AFpos], (4*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    this.debugLine++;
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.BCpos]), (0*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.DEpos]), (1*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.HLpos]), (2*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.IRpos]), (3*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.AFpos]), (4*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
  }

  void showDebugSpeRegs() {
    // Debug lines : PC, SP and IX, IY 16b registers
    this.debugLine++;
    for (int i = 0; i <= this.ga.reg.SPpos; i++) { // PC and SP
      text(this.ga.reg.speRegName[i], (i*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    }
    for (int i = this.ga.reg.IXpos; i <= this.ga.reg.IYpos; i++) { //IX and IY
      text(this.ga.reg.reg16Name[i], ((i - this.ga.reg.IXpos + this.ga.reg.SPpos + 1)*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    text(this.ga.hex4(this.ga.reg.specialReg[this.ga.reg.PCpos]), (0*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.specialReg[this.ga.reg.SPpos]), (1*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.IXpos]), (2*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.hex4(this.ga.reg.reg16b[this.ga.reg.IYpos]), (3*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
  }

  void showDebugPrimeRegs() {
    int p16;
    // Debug lines : Prime 16b registers
    fill(127, 127, 127);
    this.debugLine++;
    for (int i = 0; i <= this.ga.reg.AFpos; i++) {
      text(this.ga.reg.reg16Name[i] + "'", (i*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    p16 = (this.ga.reg.regPrime[this.ga.reg.Bpos] << 8) + this.ga.reg.regPrime[this.ga.reg.Cpos];
    text(this.ga.hex4(p16), (0*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    p16 = (this.ga.reg.regPrime[this.ga.reg.Dpos] << 8) + this.ga.reg.regPrime[this.ga.reg.Epos];
    text(this.ga.hex4(p16), (1*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    p16 = (this.ga.reg.regPrime[this.ga.reg.Hpos] << 8) + this.ga.reg.regPrime[this.ga.reg.Lpos];
    text(this.ga.hex4(p16), (2*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
    p16 = (this.ga.reg.regPrime[this.ga.reg.Apos] << 8) + this.ga.reg.regPrime[this.ga.reg.Fpos];
    text(this.ga.hex4(p16), (3*this.regxpad)+this.ga.xpad, this.debugLine*this.regypad);
  }

  void showDebugFlags() {
    // Debug lines : Flags
    fill(255, 255, 0);
    this.debugLine++;
    for (int i = this.ga.reg.SFpos; i >= this.ga.reg.CFpos; i--) {
      text(this.ga.reg.flagsName[i], (i*this.regxpad/2.0)+this.ga.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    for (int i = this.ga.reg.SFpos; i >= this.ga.reg.CFpos; i--) {
      text(this.ga.reg.getFlagBit(i), ((this.ga.reg.SFpos-i)*this.regxpad/2.0)+this.ga.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    //    text("HSync:" + this.ga.HSYNC + "; VSync:" + this.ga.VSYNC + "; Int=" + this.ga.z80.interruptAck, this.ga.xpad, this.debugLine*this.regypad);
    String crtcregval = "CRTC:";
    for (int i = 0; i < 16; i++) {
      crtcregval += hex(this.ga.CRTCreg[i], 2);
    }
    text(crtcregval, this.ga.xpad, this.debugLine*this.regypad);
    this.debugLine++;
    String psgregval = "PSG:";
    for (int i = 0; i < 16; i++) {
      psgregval += hex(this.psg.regPSG[i], 2);
    }
    text(psgregval, this.ga.xpad, this.debugLine*this.regypad);

  }

  void showDebugOpcode() {
    // show current ASM opcode (and previous one)
    this.debugLine++;
    text(this.ga.previnstrDbg, 1.5*this.regxpad+this.ga.xpad, this.debugLine*this.regypad);
    this.debugLine++;
    text("Opcode: => ", this.ga.xpad, this.debugLine*this.regypad);
    text(this.ga.instrDbg, 1.5*this.regxpad+this.ga.xpad, this.debugLine*this.regypad);
  }

  void showDebugStack(int stackaddr) {
    int memp;
    int nblines = 4;
    // Debug lines : Flags
    fill(255, 255, 0);
    this.debugLine++;
    this.debugLine++;
    text("Stack : ", this.ga.xpad, this.debugLine*this.regypad);
    text("=>", (this.regxpad)+this.ga.xpad, (this.debugLine+2)*this.regypad);
    this.debugLine++;
    memp = stackaddr + 8;
    for (int j = 0; j < nblines; j ++) {
      text(this.ga.hex4(memp), this.ga.xpad, (this.debugLine+j)*this.regypad);
      for (int i = 0; i < 8; i++) {
        text(hex(this.ga.mem.peek(memp), 2), ((i+3)*this.regxpad/2.2)+this.ga.xpad, (this.debugLine+j)*this.regypad);
        memp--;
      }
    }
    this.debugLine += nblines;
  }

  void showDebugMem(int startmem) {
    this.showDebugMem(startmem, 8, "Memory");
  }

  void showDebugMem(int startmem, int len, String title) {
    int memp;
    int nblines = len;
    // Debug lines : Flags
    fill(255, 255, 0);
    this.debugLine++;
    text(title + " : ", this.ga.xpad, this.debugLine*this.regypad);
    this.debugLine++;
    memp = startmem;
    for (int j = 0; j < nblines; j ++) {
      text(this.ga.hex4(memp), this.ga.xpad, (this.debugLine+j)*this.regypad);
      for (int i = 0; i < 8; i++) {
        text(hex(this.ga.mem.peek(memp), 2), ((i+3)*this.regxpad/2.2)+this.ga.xpad, (this.debugLine+j)*this.regypad);
        memp++;
      }
    }
    this.debugLine += nblines;
  }

  void showDebugPCMem() {
    int startmem = this.ga.reg.specialReg[this.ga.reg.PCpos] - 8;
    text("=>", (this.regxpad)+this.ga.xpad, (this.debugLine+3)*this.regypad);
    this.showDebugMem(startmem, 4, "Mem @ PC");
  }  

  void showDebugScreen () {
    //debug box
    pushMatrix();
    translate(this.ga.cpcWidth-this.xdebug-this.ga.xpad, this.ga.ypad);
    stroke(255, 255, 0);
    fill(0, 0, 127);
    rect(0, 0, this.xdebug, this.ga.nbrowfullscreen*this.ga.yscl);

    this.debugLine = 0;
    this.showDebugRegs();
    this.showDebugSpeRegs();
    this.showDebugPrimeRegs();
    this.showDebugFlags();
    this.showDebugOpcode();
    this.showDebugStack(this.ga.reg.getSP()-1);
    this.showDebugMem(this.debugMem);
    this.showDebugPCMem();

    popMatrix();
  }
}