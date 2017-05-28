/*================================================================= //<>// //<>// //<>//
 =
 = Multiple Level Inheritance:
 =
 = Instruction extends:
 = InstrLD8 extends:
 = InstrLD16 extends:
 = InstrAL8 extends:
 = InstrAL16 extends:
 = InstrExTxSrch extends:
 = InstrStack extends:
 = InstrJmp extends:
 = InstrCall extends:
 = InstrBSRT extends:
 = InstrRotShft extends:
 = InstrGPACC extends:
 = InstrIO extends:
 =  ... InstrWrap
 =
 ==================================================================*/

class InstrWrap {
  //opcode, AsmInstruction, Mcycles, Tcycles, Rcycles, byteParam, operationToEvaluate, comment
  String opcode;
  String asmInstr;
  int Pcycles;
  int Mcycles;
  int Tcycles;
  int Rcycles;
  int param;
  String op2eval;
  String comment;

  Registers reg;
  Pinout pin;
  Memory mem;
  Firmware fwv;

  // ====================================================================
  void setOpcode(String s) {
    this.opcode = s;
  }

  // set ProgCount, Machine, Timing, Refresh cycle values and number of parameters
  void setPMTRpCycles(int p, int m, int t, int r, int tp) {
    this.Pcycles = p; // si <0, PC n'est pas mis a jour par Pcycles mais par l'instruction
    this.Mcycles = m;
    this.Tcycles = t;
    this.Rcycles = r;
    this.param = tp;
  }

  // ====================================================================
  String hex2 (int val8) {
    return "0x" + hex(val8, 2);
  }

  String hex4 (int val16) {
    return "0x" + hex(val16, 4);
  }

  // ====================================================================
  String regNameRS (int num) {
    return this.reg.regName[num];
  }

  String regNameD (int num) {
    if (num < 3) {
      return this.reg.reg16Name[num];
    } else {
      return this.reg.speRegName[this.reg.SPpos];
    }
  }

  String regNameQ (int num) {
    return this.reg.reg16Name[num];
  }

  String regNameX (int num) {
    switch (num) {
    case 2: 
      return this.reg.reg16Name[this.reg.IXpos];
    case 3: 
      return this.reg.speRegName[this.reg.SPpos];
    default: 
      return this.reg.reg16Name[num];
    }
  }

  String regNameY (int num) {
    switch (num) {
    case 2: 
      return this.reg.reg16Name[this.reg.IYpos];
    case 3: 
      return this.reg.speRegName[this.reg.SPpos];
    default: 
      return this.reg.reg16Name[num];
    }
  }

  // -----------------------------------------------------------------------------------
  // Flags calc and access methods
  // -----------------------------------------------------------------------------------

  void setFlagsAddType(int res, int operand1, int operand2) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(res);
    zf = this.isZero(res); 
    yf = this.rshiftMask(res, this.reg.YFpos, 0x01);
    hf = this.halfCarry(operand1, operand2);
    xf = this.rshiftMask(res, this.reg.XFpos, 0x01);
    nf = 0;
    pvf = this.oVerflow(operand1, operand2, res, nf);
    cf = this.carry(operand1, operand2);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsIncType (int preval8, int val8) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(val8);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = this.halfCarry(preval8, 1);
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = (preval8 == 0x7F) ? 1 : 0;
    nf = 0;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsSubType (int res, int op1, int op2) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(res);
    zf = this.isZero(res); 
    yf = this.rshiftMask(res, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(op1, op2);
    xf = this.rshiftMask(res, this.reg.XFpos, 0x01);
    nf = 1;
    pvf = this.oVerflow(op1, op2, res, nf);
    cf = this.borrow(op1, op2);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsCpType (int compa, int a, int val8) {
    this.setFlagsSubType(compa, a, val8);
  }

  void setFlagsDecType (int preva, int res) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(res);
    zf = this.isZero(res); 
    yf = this.rshiftMask(res, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(preva, 1);
    xf = this.rshiftMask(res, this.reg.XFpos, 0x01);
    pvf = (preva == 0x80) ? 1 : 0;
    nf = 1;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsAndType (int val8) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(val8);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 1;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.parity(val8); // Zilog Z80 User Manual "UM008011-0816" page 158 is incorrect: it should be the parity, not the Overflow
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsOrType (int val8) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(val8);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.parity(val8); // Zilog Z80 User Manual "UM008011-0816" page 160 is incorrect: it should be the parity, not the Overflow
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsXorType (int val8) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(val8);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.parity(val8);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsInType (int val8) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(val8);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.parity(val8);
    nf = 0;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  void setFlagsRotType (int val8, int car) {
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.isNeg(val8);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.parity(val8);
    nf = 0;
    cf = car;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  //---------------------------------------------------------------------------------------------
  // 8bit 2's complement value to signed value
  int twoComp2signed (int twoscomp) {
    int jmp = twoscomp;
    if (twoscomp >= 0x80) {
      jmp = (twoscomp & 0x7F) - 128;
    }
    return jmp;
  }

  // bit7(a) xor bit7(b) = 0 if a anf b both have the same sign
  boolean haveSameSign(int a, int b) {
    return (((a ^ b) & 0x80) == 0);
  }

  //add (Nflag=0) : if a and b different sign : NO overflow
  //add (Nflag=0) : if a and b same sign      : overflow if sign of result != than sign of operands
  //sub (Nflag=1) : if a and b same sign      : NO overflow
  //sub (Nflag=1) : if a and b different sign : overflow if sign of result != than sign of first operand
  int oVerflow (int a, int b, int res, int nf) {
    boolean isSub = (nf == 1);
    boolean operandsSameSign = this.haveSameSign(a, b);
    boolean resSameSignOperands = this.haveSameSign(a, res);
    return ((isSub ^ operandsSameSign) && (!resSameSignOperands)) ? 1 : 0;
  }

  // Return the Half-Carry bit from the 2 input bytes that we want to add.
  int halfCarry (int a, int b) {
    return ((((a & 0x0F) + (b & 0x0F)) & 0x0010) >> 4);
    // also HF = (a ^ b ^ (a + b)) & 0x10;
  }

  // Return the Carry bit from the 2 input bytes that we want to add.
  int carry (int a, int b) {
    return ((((a & 0xFF) + (b & 0xFF)) & 0x0100) >> 8);
  }

  int halfBorrow (int a, int b) {
    return ((a & 0x0F) < (b & 0x0F)) ? 1 : 0;
  }

  int borrow (int a, int b) {
    return (a < b) ? 1 : 0;
  }

  int parity (int a) {
    // 1 : even parity (even number of '1' in the byte); 0: odd parity
    int p = 1;
    for (int i = 0; i < 8; i++) {
      p ^= (a >> i) & 0x01; // xor
    }
    return p;
  }

  int isNeg (int val) {
    return this.rshiftMask(val, this.reg.SFpos, 0x01); // ret 1 if 2's complement is neg, i.e. if bit7 = 1
  }

  int isZeroMask (int val, int mask) {
    return ((val & mask) == 0) ? 1 : 0;
  }

  int isNotZeroMask (int val, int mask) {
    return (1 - this.isZeroMask(val, mask)); // 1-0=1 (inv 0); 1-1=0 (inv 1)
  }

  int isZero (int val) {
    return this.isZeroMask(val, 0xFF);
  }

  int isNotZero (int val) {
    return this.isNotZeroMask(val, 0xFF);
  }

  int isZero16 (int val) {
    return this.isZeroMask(val, 0xFFFF);
  }

  int isNotZero16 (int val) {
    return this.isNotZeroMask(val, 0xFFFF);
  }

  // ----------------------------------------------------------------------

  int rshiftMask (int val, int shft, int msk) {
    return (val >> shft) & msk;
  }

  int maskRShift (int val, int shft, int msk) {
    return (val & msk) >> shft;
  }

  int lshiftMask (int val, int shft, int msk) {
    return (val << shft) & msk;
  }

  int maskLShift (int val, int shft, int msk) {
    return (val & msk) << shft;
  }

  void swapReg (int r1, int r2) {
    int tswap = this.getRegVal(r1);
    this.setRegVal(r1, this.getRegVal(r2));
    this.setRegVal(r2, tswap);
  }

  void swapPrime (int r) {
    int tswap = this.reg.regPrime[r] & 0xFF;
    this.reg.regPrime[r] = this.getRegVal(r);
    this.setRegVal(r, tswap);
  }

  // ========================================================================
  // Registers access methods
  // ========================================================================
  // set 8b reg with 8b val
  void setRegVal (int r, int val8) {
    this.reg.reg8b[r] = (val8 & 0xFF);
  }

  // set 16b reg with 16bval
  void setReg16Val (int d, int val16) {
    if (d >= this.reg.IXpos) {
      this.reg.reg16b[d] = (val16 & 0xFFFF);
    } else {
      this.setReg2x8Val(d, val16);
    }
  }

  // set 2 x 8b regs from one 16b value
  // r  0    1    2    3    4    5     6      7    8    9   10
  //  {"B", "C", "D", "E", "H", "L", "(HL)", "A", "F", "I", "R"};
  // d  0     1     2     3     4     5     6
  // 2d 0     2     4     6     7     10    12
  //  {"BC", "DE", "HL", "AF", "IR", "IX", "IY"};
  void setReg2x8Val (int d, int val16) {
    int r;
    if (d >= this.reg.IXpos) {
      this.setReg16Val(d, val16);
    } else {
      r = 2*d;
      if (d >= this.reg.AFpos) {
        r++;
      }
      this.setRegVal(r + 1, ((val16 >> 0) & 0xFF)); // LSB
      this.setRegVal(r + 0, ((val16 >> 8) & 0xFF)); // MSB
    }
  }

  // ----------------------------------------------------------------------
  // put a 8b Byte at a 16b memory address
  void putInPointer (int pointer16, int val8) {
    this.mem.poke(pointer16, val8 & 0xFF); // byte
  }

  // put a 8b Byte at a 16b memory address pointed by a double-register
  void putInRegPointer (int reg16nb, int val8) {
    int pointer = this.getReg16Val(reg16nb);
    this.putInPointer(pointer, val8);
  }

  // put a 16b Word at a 16b memory address (LSB@addr, MSB@addr+1)
  void put16InPointer (int pointer16, int val16) {
    this.putInPointer((pointer16 + 0), this.rshiftMask(val16, 0, 0x00FF)); // LSB
    this.putInPointer((pointer16 + 1), this.rshiftMask(val16, 8, 0x00FF)); // LSB
  }

  // put a 16b Word at a 16b memory address pointed by a double-register (LSB@addr, MSB@addr+1)
  void put16InRegPointer (int reg16nb, int val16) {
    int pointer = this.getReg16Val(reg16nb);
    this.put16InRegPointer(pointer, val16);
  }

  // ----------------------------------------------------------------------

  // get value of 8b reg
  int getRegVal (int r) {
    return (this.reg.reg8b[r] & 0xFF);
  }

  // get value of 16b reg
  int getReg16Val (int d) {
    return (this.reg.reg16b[d] & 0xFFFF);
  }

  // ----------------------------------------------------------------------

  // get a 8b Byte from a 16b memory address
  int getFromPointer (int pointer16) {
    return (this.mem.peek(pointer16) & 0xFF);
  }

  // get a 8b Byte from a 16b memory address pointed by a double-register
  int getFromRegPointer (int reg16nb) {
    int pointer16 = this.getReg16Val(reg16nb);
    return this.getFromPointer(pointer16);
  }

  // get a 16b Word from a 16b memory address (LSB@addr, MSB@addr+1)
  int get16FromPointer (int pointer16) {
    int val = this.getFromPointer(pointer16); // LSB
    val    += this.maskLShift(this.getFromPointer(pointer16 + 1), 8, 0xFF); // MSB
    return val;
  }

  // get a 16b Word from a 16b memory address pointed by a double-register (LSB@addr, MSB@addr+1)
  int get16FromRegPointer (int reg16nb) {
    int pointer16 = this.getReg16Val(reg16nb);
    return this.get16FromPointer(pointer16);
  }

  // ========================================================================
  // put 2x8b words in the Stack (16b addr)
  void putInStack (int vall, int valh) {
    int stackPointer = this.reg.specialReg[this.reg.SPpos];
    stackPointer--;
    this.mem.poke(stackPointer, this.rshiftMask(valh, 0, 0xFF)); // MSB
    stackPointer--;
    this.mem.poke(stackPointer, this.rshiftMask(vall, 0, 0xFF)); // LSB
    this.reg.specialReg[this.reg.SPpos] = stackPointer;
  }

  // put a 16b word in the Stack (16b addr)
  void put16InStack (int val16) {
    int vall = this.rshiftMask(val16, 0, 0xFF);
    int valh = this.rshiftMask(val16, 8, 0xFF);
    this.putInStack(vall, valh);
  }

  // get 2x8b word from the Stack (16b addr)
  int[] getFromStack () {
    int stackPointer = this.reg.specialReg[this.reg.SPpos];
    int val[] = new int[2]; //0: LSB; 1: MSB
    val[0] = this.maskLShift(this.mem.peek(stackPointer), 0, 0xFF); // LSB
    stackPointer++;
    val[1] = this.maskLShift(this.mem.peek(stackPointer), 0, 0xFF); // MSB
    stackPointer++;
    this.reg.specialReg[this.reg.SPpos] = stackPointer;
    return val;
  }

  // get a 16b word from the Stack (16b addr)
  int get16FromStack () {
    int val[] = new int[2]; //0: LSB; 1: MSB
    val = this.getFromStack();
    return (val[1] << 8) + val[0];
  }
}