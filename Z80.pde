// Z80

class Z80 {
  Registers reg;
  Opcodes opcode;
  Pinout pin;

  Firmware rom; // ref
  RAM ram; // ref

  int pc;
  int fetch;
  int opcodes[];
  boolean halted;

  Z80 (RAM memref, Firmware romref) {
    this.reg = new Registers();
    this.ram = memref;
    this.rom = romref;
    this.opcode = new Opcodes(this.reg, this.ram, this.rom);
    this.pin = new Pinout();
    this.fetch = 4;
    this.opcodes = new int[this.fetch];
    this.halted = true;
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

  void step () {
    if (!this.halted) {
      this.pc = this.reg.specialReg[this.reg.PCpos];
      for (int i = 0; i < this.fetch; i++) {
        this.opcodes[i] = this.ram.peek(pc + i);
      }
      this.opcode.OpCodeSel(this.opcodes);
    }
  }

  void step (int n) {
    for (int i = 0; i < n; i++) {
      this.step();
    }
  }
}