/*###############################################################
 #
 # Bit Set, Reset and Test Group
 #
 + BIT b,r
 + BIT b,(HL)
 + SET b,r
 + SET b,(HL)
 + RES b,r
 + RES b,(HL)
 #
 ###############################################################*/

class InstrBSRT extends InstrRotShft {

  // -----------------------------------------------------------------------------------------------------
  void BITbr (int b, int r) {
    int val8;
    String rName = this.regNameRS(r);
    this.asmInstr = "BIT " + b + ", " + rName;
    if (r == this.reg.contHLpos) {
      int hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.setPMTRpCycles(2, 3, 12, 2, 0);
    } else { 
      val8 = this.getRegVal(r);
      this.setPMTRpCycles(2, 2, 8, 2, 0);
    }
    int z = (((val8 >> b) & 0x01) == 0) ? 1 : 0; // si bit=0, Z=1 sinon Z=0
    this.comment = "";

    //Flags:
    this.reg.writeFlagBit(this.reg.ZFpos, z);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.setFlagBit(this.reg.HFpos);
  }

  // -----------------------------------------------------------------------------------------------------
  void SETbr (int b, int r) {
    int val8;
    int hl = 0;
    String rName = this.regNameRS(r);
    this.asmInstr = "SET " + b + ", " + rName;
    if (r == this.reg.contHLpos) {
      hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.setPMTRpCycles(2, 4, 15, 2, 0);
    } else { 
      val8 = this.getRegVal(r);
      this.setPMTRpCycles(2, 2, 8, 2, 0);
    }
    val8 |= (0x01 << b);
    if (r == this.reg.contHLpos) {
      this.putInPointer(hl, val8);
    } else {
      this.setRegVal(r, val8);
    }
    this.comment = "value = " + hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void RESbr (int b, int r) {
    int val8;
    int hl = 0;
    String rName = this.regNameRS(r);
    this.asmInstr = "RES " + b + ", " + rName;
    if (r == this.reg.contHLpos) {
      hl = this.getReg16Val(this.reg.HLpos);
      val8 = this.getFromPointer(hl);
      this.setPMTRpCycles(2, 4, 15, 2, 0);
    } else { 
      val8 = this.getRegVal(r);
      this.setPMTRpCycles(2, 2, 8, 2, 0);
    }
    val8 &= ~(0x01 << b);
    if (r == this.reg.contHLpos) {
      this.putInPointer(hl, val8);
    } else {
      this.setRegVal(r, val8);
    }
    this.comment = "value = " + hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void BITbIXY (int b, int ixy, int twoscomp) {
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    //String rName = this.regNameRS(r);
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy] + sign + abs(displacement);    
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "BIT " + b + ", (" + ixyName + ")";
    this.setPMTRpCycles(4, 5, 20, 2, 2);
    int z = (((val8 >> b) & 0x01) == 0) ? 1 : 0; // si bit=0, Z=1 sinon Z=0
    this.comment = "";

    //Flags:
    this.reg.writeFlagBit(this.reg.ZFpos, z);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.setFlagBit(this.reg.HFpos);
  }

  // -----------------------------------------------------------------------------------------------------
  void SETbIXY (int b, int ixy, int r, int twoscomp) {
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    String rName = this.regNameRS(r);
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy] + sign + abs(displacement);    
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "SET " + b + ", (" + ixyName + ")";
    this.setPMTRpCycles(4, 6, 23, 2, 2);
    val8 |= (0x01 << b);
    this.putInPointer(mem16, val8);
    if (r != 6) {
      this.setRegVal(r, val8);
      this.asmInstr += ", " + rName;
    }
    this.comment = "value = " + hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void RESbIXY (int b, int ixy, int r, int twoscomp) {
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    String rName = this.regNameRS(r);
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy] + sign + abs(displacement);    
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "RES " + b + ", (" + ixyName + ")";
    this.setPMTRpCycles(4, 6, 23, 2, 2);
    val8 &= ~(0x01 << b);
    this.putInPointer(mem16, val8);
    if (r != 6) {
      this.setRegVal(r, val8);
      this.asmInstr += ", " + rName;
    }
    this.comment = "value = " + hex2(val8);
  }
}