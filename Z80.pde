// Z80

class Z80 {
  Registers reg;
  Opcodes opcode;
  Pinout pin;

  Firmware fwv; // ref
  Memory mem; // Ref

  // RAM ram; // ref
  // ROM rom; // ref

  int pc;
  private final int fetch = 4; // fetch the next 4 bytes at every new PC (not all of them will be used, but up to all of them can be usefull for one instruction)
  int opcodeBytes[];
  boolean halted;

  int reset = 0;
  boolean interruptPending = false;
  boolean interruptAck = false;
  boolean nmi = false;


  Z80 () {
    this.reg = new Registers();
    this.pin = new Pinout();
    this.opcode = new Opcodes();
    this.opcodeBytes = new int[this.fetch];
    this.halted = true;
    this.reset = 0;
    this.interruptPending = false;
    this.interruptAck = false;
    this.nmi = false;
  }

  void setRef(Memory memref, Firmware fwvref, GateArray garef, PSG psgref) {
    this.mem = memref;
    this.fwv = fwvref;
    this.opcode.setRef(this.reg, this.pin, memref, fwvref);
    this.pin.setRef(memref, garef, psgref);
  }

  void initPC (int val) {
    this.reg.specialReg[this.reg.PCpos] = val;
  }

  void halt () {
    this.halted = true;
  }

  void go () {
    this.halted = false;
  }

  void update () {
    this.pin.INT_b = (this.interruptPending) ? 0 : 1;  //Active low; Invert val (0=>1; 1=>0)
    this.pin.NMI_b = (this.nmi) ? 0 : 1;  //Active low; Invert val (0=>1; 1=>0)
    this.pin.RESET_b = (1 - this.reset);  //Active low; Invert val (0=>1; 1=>0)
  }

  void step () {
    if (!this.halted) {
      this.update();
      this.pc = this.reg.specialReg[this.reg.PCpos];
      // fetch the next 4 bytes at every new PC
      // (not all of them will be used, but up to all of them can be usefull for one instruction),
      for (int i = 0; i < this.fetch; i++) {
        this.opcodeBytes[i] = this.mem.peek(pc + i);
      }
      this.opcode.OpCodeSel(this.opcodeBytes);
      this.interruptReq(this.opcodeBytes[0]);
    }
  }

  void step (int n) {
    for (int i = 0; i < n; i++) {
      this.step();
    }
  }

  void interruptReq (int prevOpcode) {
    // if no IRQ or if interrupt not enabled then no need to go further
    if (((!this.interruptPending) || (this.reg.IFF1 == 0)) && (!this.interruptAck)) {
      this.interruptPending = false;
      return;
    } else {
      this.interruptAck = true;
      this.interruptPending = false;
    }
    // If Opcode is EI then postpone the int handling after the next instruction
    if (prevOpcode == 0xFB) {
      return;
    }
    this.reg.IFF1 = 0; // Does a "DI"
    this.reg.IFF2 = 0; // Does a "DI"
    switch (this.reg.IM) {
    case 0 :
      println("Interrupt Mode 0 Not supported on CPC");
      //int rstNb = this.pin.DATA;
      //this.opcodes.RST(int rstNb);
      break;
    case 2 :
      println("Vectored Interrupt Mode (2) not implemented (yet)");
      int addr = (this.reg.reg8b[this.reg.Ipos] << 8) + this.pin.DATA;
      this.reg.specialReg[this.reg.PCpos] = addr;
      break;
    default : // IM 1 : RST 0x38
      this.opcode.instr.CPURSTp(7);
    }
    this.interruptPending = false;
    this.interruptAck = false;
  }
}