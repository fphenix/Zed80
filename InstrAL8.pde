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
    String rName = this.regNameRS(r);
    this.asmInstr = "ADD A, " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADDAp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "ADD A, " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCAp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "ADC A, " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAddType(a, preva, val8);
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
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      prev = this.getRegVal(r);
      val8 = prev + 1;
      this.setRegVal(r, val8);
    }
    this.comment = "value = " + this.hex2(val8);
    this.setFlagsIncType(prev, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCAr (int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "ADC A, " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADDAval (int val8) {
    this.asmInstr = "ADD A, " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCAval (int val8) {
    this.asmInstr = "ADC A, " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SUBr (int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "SUB " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SUBp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "SUB " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsSubType(a, preva, val8);
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
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      prev = this.getRegVal(r);
      val8 = prev - 1;
      this.setRegVal(r, val8);
    }
    this.comment = "value = " + this.hex2(val8);
    this.setFlagsDecType(prev, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SUBval (int val8) {
    this.asmInstr = "SUB " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCAr (int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "SBC A, " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    val8 +=  this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCAp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "SBC A, " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCAval (int val8) {
    this.asmInstr = "SBC A, " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    val8 +=  this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ANDAr (int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "AND " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva & val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAndType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void ORAr (int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "OR " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva | val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsOrType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void XORAr (int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "XOR " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva ^ val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsXorType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPr (int r) {
    int val8;
    int a, compa;
    String rName = this.regNameRS(r);
    this.asmInstr = "CP " + rName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      val8 = this.getRegVal(r);
    }
    a = this.getRegVal(this.reg.Apos);
    compa = a - val8;
    this.comment = "Compare = " + this.hex2(compa);
    this.setFlagsCpType(compa, a, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ANDp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "AND " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = preva & val8;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAndType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void ORp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "OR " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = preva | val8;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsOrType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void XORp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    int preva = this.getRegVal(this.reg.Apos);
    this.asmInstr = "XOR " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int a = preva ^ val8;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsXorType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPp (int ixy, int horl) {
    int val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      val8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    int a = this.getRegVal(this.reg.Apos);
    this.asmInstr = "CP " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    int compa = (a - val8) & 0xFF;
    this.comment = "value = " + this.hex2(compa);
    this.setFlagsCpType(compa, a, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void INCp (int ixy, int horl) {
    int preval8, val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      preval8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      preval8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    this.asmInstr = "INC " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    val8 = (preval8 + 1) & 0xFF;
    this.comment = "value = " + this.hex2(val8);
    this.setFlagsIncType(preval8, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void DECp (int ixy, int horl) {
    int preval8, val8;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      preval8 = (val16 & 0xFF00) >> 8;
      ixyName += "h";
    } else {
      preval8 = (val16 & 0x00FF) >> 0;
      ixyName += "l";
    }
    this.asmInstr = "DEC " + ixyName;
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    val8 = (preval8 - 1) & 0xFF;
    this.comment = "value = " + this.hex2(val8);
    this.setFlagsDecType(preval8, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ANDAval (int val8) {
    this.asmInstr = "AND " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva & val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsAndType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void ORAval (int val8) {
    this.asmInstr = "OR " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva | val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsOrType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void XORAval (int val8) {
    this.asmInstr = "XOR " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva ^ val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.setFlagsXorType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPval (int val8) {
    int a, compa;
    this.asmInstr = "CP " + this.hex2(val8);
    this.setPMTRpCycles(2, 2, 7, 1, 1);
    a = this.getRegVal(this.reg.Apos);
    compa = a - val8;
    this.comment = "Compare = " + this.hex2(compa);
    this.setFlagsCpType(compa, a, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADDAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "ADD A, " + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "ADC A, " + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva + val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsAddType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SUBcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "SUB " + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "SBC A, " + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    val8 += this.reg.getCF();
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva - val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsSubType(a, preva, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void ANDAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "AND (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva & val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "Value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsAndType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void ORAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "OR (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva | val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "Value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsOrType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void XORAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "XOR (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    int preva = this.getRegVal(this.reg.Apos);
    int a = (preva ^ val8) & 0xFF;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "Value = " + this.hex2(a);
    this.comment += "; displacement = " + sign + abs(displacement);
    this.setFlagsXorType(a);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPAcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "CP (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    int a = this.getRegVal(this.reg.Apos);
    int compa = (a - val8) & 0xFF;
    this.comment = "displacement = " + sign + abs(displacement);
    this.setFlagsCpType(compa, a, val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void INCcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "INC (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 6, 26, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int preval8 = this.getFromPointer(mem16);
    int val8 = preval8 + 1;
    this.putInPointer(mem16, val8);
    this.comment = "displacement = " + sign + abs(displacement);
    this.setFlagsIncType(preval8, val8);
  }
  // -----------------------------------------------------------------------------------------------------
  void DECcontIXYtc (int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "DEC (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 6, 26, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int preval8 = this.getFromPointer(mem16);
    int val8 = preval8 - 1;
    this.putInPointer(mem16, val8);
    this.comment = "displacement = " + sign + abs(displacement);
    this.setFlagsDecType(preval8, val8);
  }
}