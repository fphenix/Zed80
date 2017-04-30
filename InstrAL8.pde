/*###############################################################
 #
 # 8-Bit Arithmetic and Logical Group
 #
 + ADD A,r
 # ADD A,p
 # ADD A,q
 + ADD A,n
 + ADD A,(HL)
 + ADC A,r
 # ADC A,p
 # ADC A,q
 + ADC A,n
 + ADC A,(HL)
 + SUB r
 # SUB p
 # SUB q
 + SUB n
 + SUB (HL)
 + SBC A,r
 # SBC A,p
 # SBC A,q
 + SBC A,n
 + SBC A,(HL)
 + AND r
 # AND p
 # AND q
 + AND n
 + AND (HL)
 + OR r
 # OR p
 # OR q
 + OR n
 + OR (HL)
 + XOR r
 # XOR p
 # XOR q
 + XOR n
 + XOR (HL)
 + CP r
 # CP p
 # CP q
 + CP n
 + CP (HL)
 + INC r
 # INC p
 # INC q
 + INC (HL)
 + DEC r
 # DEC p
 # DEC q
 + DEC (HL)
 # ADD A,(IX+d)
 # ADD A,(IY+d)
 # ADC A,(IX+d)
 # ADC A,(IY+d)
 # SUB (IX+d)
 # SUB (IY+d)
 # SBC A,(IX+d)
 # SBC A,(IY+d)
 # AND (IX+d) ; d is a 2's complement
 # AND (IY+d)
 # OR (IX+d) ; d is a 2's complement
 # OR (IY+d)
 # XOR (IX+d)
 # XOR (IY+d)
 # CP (IX+d)
 # CP (IY+d)
 # INC (IX+d)
 # INC (IY+d)
 # DEC (IX+d)
 # DEC (IY+d)
 #
 ###############################################################*/

class InstrAL8 extends InstrAL16 {

  // -----------------------------------------------------------------------------------------------------
  void ADDAr (int r) {
    int val8;
    int a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "ADD A, " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment = "Add memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "Add register " + rName + " content (";
    }
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva + val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + ") to Accumulator, result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfCarry(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = this.carry(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void INCr (int r) {
    int val8;
    int prev;
    String rName = this.regNameRS(r);
    this.asmInstr = "INC " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 3, 11, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      prev = this.getFromPointer(hl);
      val8 = prev + 1;
      this.putInRegPointer(this.reg.HLpos, val8);
      this.comment = "Increments memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      prev = this.getRegVal(r);
      val8 = prev + 1;
      this.setRegVal(r, val8);
      this.comment = "Increments register " + rName + " content (";
    }
    this.comment += this.hex2(prev) + "), result = " + this.hex2(val8) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(val8, this.reg.SFpos, 0x01);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = this.halfCarry(prev, val8);
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = (prev == 0x7F) ? 1 : 0;
    nf = 0;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCAr (int r) {
    int val8;
    int a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "ADC A, " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment = "Add-plus-carry the content of the memory address pointed by " + rName + " (";
      this.comment += this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "Add-plus-carry register " + rName + " content (";
    }
    val8 += this.reg.getCF();
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva + val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + ") to Accumulator, result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfCarry(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = this.carry(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADDAval (int val8) {
    int a, preva;
    this.asmInstr = "ADD A, " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva + val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Add (" + this.hex2(val8) + ") to Accumulator, result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfCarry(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = this.carry(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCAval (int val8) {
    int a, preva;
    this.asmInstr = "ADC A, " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    val8 += this.reg.getCF();
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva + val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Add-plus-carry (" + this.hex2(val8) + ") to Accumulator, result = ";
    this.comment += this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfCarry(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = this.carry(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void SUBr (int r) {
    int val8, a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "SUB " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment = "Sub the content of the memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "Sub register " + rName + " content (";
    }
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva - val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + ") to Accumulator, result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva-val8);
    nf = 1;
    cf = this.borrow(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void DECr (int r) {
    int val8;
    int prev;
    String rName = this.regNameRS(r);
    this.asmInstr = "DEC " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 3, 11, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      prev = this.getFromPointer(hl);
      val8 = prev - 1;
      this.putInRegPointer(this.reg.HLpos, val8);
      this.comment = "Decrements memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      prev = this.getRegVal(r);
      val8 = prev - 1;
      this.setRegVal(r, val8);
      this.comment = "Decrements register " + rName + " content (";
    }
    this.comment += this.hex2(prev) + "), result = " + this.hex2(val8) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(val8, this.reg.SFpos, 0x01);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(prev, val8);
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = (prev == 0x80) ? 1 : 0;
    nf = 1;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void SUBval (int val8) {
    int a, preva;
    this.asmInstr = "SUB " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva - val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Sub value " + this.hex2(val8) + ") from Accumulator, result = ";
    this.comment += this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva-val8);
    nf = 1;
    cf = this.borrow(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCAr (int r) {
    int val8, a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "SBC A, " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment = "Sub-plus_carry the content of the memory address pointed by " + rName + " (";
      this.comment += this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "Sub-plus_carry register " + rName + " content (";
    }
    preva = this.getRegVal(this.reg.Apos);
    val8 +=  this.reg.getCF();
    this.setRegVal(this.reg.Apos, preva - val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + ") to Accumulator, result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva-val8);
    nf = 1;
    cf = this.borrow(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCAval (int val8) {
    int a, preva;
    this.asmInstr = "SBC A, " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    preva = this.getRegVal(this.reg.Apos);
    val8 +=  this.reg.getCF();
    this.setRegVal(this.reg.Apos, preva - val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Sub-plus_carry value " + this.hex2(val8) + ") from Accumulator, result = ";
    this.comment += this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(preva, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva-val8);
    nf = 1;
    cf = this.borrow(preva, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ANDAr (int r) {
    int val8;
    int a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "AND " + rName;
    this.comment = "Bitwise AND between the Accumulator and the value ";
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment += "at the memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "in the register " + rName + " content (";
    }
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva & val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + "), result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = 1;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ORAr (int r) {
    int val8;
    int a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "OR " + rName;
    this.comment = "Bitwise OR between the Accumulator and the value ";
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment += "at the memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "in the register " + rName + " content (";
    }
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva | val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + "), result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void XORAr (int r) {
    int val8;
    int a, preva;
    String rName = this.regNameRS(r);
    this.asmInstr = "XOR " + rName;
    this.comment = "Bitwise eXclusive-OR between the Accumulator and the value ";
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment += "at the memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "in the register " + rName + " content (";
    }
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva ^ val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment += this.hex2(val8) + "), result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.parity(a);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPr (int r) {
    int val8;
    int a, compa;
    String rName = this.regNameRS(r);
    this.asmInstr = "CP " + rName;
    this.comment = "Compare content of Accumulator with value ";
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.comment += "at the memory address pointed by " + rName + " (" + this.hex4(hl) + ": ";
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
      this.comment = "in the register " + rName + " content (";
    }
    a = this.getRegVal(this.reg.Apos);
    compa = a - val8;
    this.comment += this.hex2(val8) + "), Accu not modified; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(compa, this.reg.SFpos, 0x01);
    zf = this.isZero(compa); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(a, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(a, val8, a-val8);
    nf = 1;
    cf = this.borrow(a, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ANDAval (int val8) {
    int a, preva;
    this.asmInstr = "AND " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva & val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Bitwise AND between the Accumulator and the value ";
    this.comment += this.hex2(val8) + "), result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = 1;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ORAval (int val8) {
    int a, preva;
    this.asmInstr = "OR " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva | val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Bitwise OR between the Accumulator and the value ";
    this.comment += this.hex2(val8) + "), result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, val8, preva+val8);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void XORAval (int val8) {
    int a, preva;
    this.asmInstr = "XOR " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    preva = this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, preva ^ val8);
    a = this.getRegVal(this.reg.Apos);
    this.comment = "Bitwise eXclusive-OR between between the Accumulator and the value ";
    this.comment += this.hex2(val8) + "), result = " + this.hex2(a) + "; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.parity(a);
    nf = 0;
    cf = 0;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPval (int val8) {
    int a, compa;
    this.asmInstr = "CP " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    a = this.getRegVal(this.reg.Apos);
    compa = a - val8;
    this.comment = "Compare content of Accumulator with value " + this.hex2(val8);
    this.comment += ", Accu not modified; Refresh Flags";

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(compa, this.reg.SFpos, 0x01);
    zf = this.isZero(compa); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.halfBorrow(a, val8);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(a, val8, a-val8);
    nf = 1;
    cf = this.borrow(a, val8);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }
}