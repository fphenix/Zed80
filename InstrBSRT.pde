/*###############################################################
 #
 # Bit Set, Reset and Test Group
 #
 + BIT b,r
 + BIT b,(HL)
 # SET b,r
 # SET b,(HL)
 # RES b,r
 # RES b,(HL)
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
    this.comment = "Test Bit n°"+b+" in register " + rName + " and set Z to " + z;

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
    this.comment = "Set Bit n°"+b+" in register " + rName;
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
    this.comment = "Reset Bit n°"+b+" in register " + rName;
  }

}