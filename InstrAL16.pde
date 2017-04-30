/*###############################################################
 #
 # 16-Bit Artithmetic Group
 #
 # ADD HL,ss
 # ADC HL,ss
 # SBC HL,ss
 # ADD IX,pp
 # ADD IY,qq
 + INC ss ; ss=BC,DE,HL,SP
 + INC IX
 + INC IY
 + DEC ss ; ss=BC,DE,HL,SP
 + DEC IX
 + DEC IY
 #
 ###############################################################*/

class InstrAL16 extends InstrExTxSrch {

  // -----------------------------------------------------------------------------------------------------
  void INCs (int d) {
    int val16;
    int prev;
    String dName = this.regNameD(d);
    this.asmInstr = "INC " + dName;
    this.setPMTRpCycles(1, 1, 6, 1, 0);
    if (d <= this.reg.HLpos) {
      prev = this.getReg16Val(d);
      val16 = prev + 1;
      this.setReg16Val(d, val16);
    } else {
      prev = this.reg.specialReg[this.reg.SPpos];
      val16 = prev + 1;
      this.reg.specialReg[this.reg.SPpos] = val16 & 0xFFFF;
    }
    this.comment = "Increments 16b register " + dName + " content (";
    this.comment += this.hex4(prev) + "), result = " + this.hex4(val16) + "; Flags untouched";
  }

  // -----------------------------------------------------------------------------------------------------
  void ADDHLs (int d) {
    int val16;
    int prev, hl, cf, hf;
    String dName = this.regNameD(d);
    this.asmInstr = "ADD HL, " + dName;
    this.setPMTRpCycles(3, 3, 11, 1, 0);
    hl = this.getReg16Val(this.reg.HLpos);
    if (d <= this.reg.HLpos) {
      prev = this.getReg16Val(d);
    } else {
      prev = this.reg.specialReg[this.reg.SPpos];
    }
    val16 = prev + hl;
    cf = ((val16 & 0x10000) >> 16);
    hf = ((val16 & 0x01000) >> 12); // to verify
    this.setReg16Val(this.reg.HLpos, val16);
    this.comment = "ADDs 16b register " + dName + " content (";
    this.comment += this.hex4(prev) + ") to HL (" + this.hex4(hl) + ") , result = ";
    this.comment += this.hex4(val16) + "; a few flags modified";

    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeCF(cf);   
    this.reg.writeHF(hf);
  }

  // -----------------------------------------------------------------------------------------------------
  void DECs (int d) {
    int val16;
    int prev;
    String dName = this.regNameD(d);
    this.asmInstr = "DEC " + dName;
    this.setPMTRpCycles(1, 1, 6, 1, 0);
    if (d <= this.reg.HLpos) {
      prev = this.getReg16Val(d);
      val16 = prev - 1;
      this.setReg16Val(d, val16);
    } else {
      prev = this.reg.specialReg[this.reg.SPpos];
      val16 = prev - 1;
      this.reg.specialReg[this.reg.SPpos] = val16 & 0xFFFF;
    }
    this.comment = "Decrements 16b register " + dName + " content (";
    this.comment += this.hex4(prev) + "), result = " + this.hex4(val16) + "; Flags untouched";
  }

  // -----------------------------------------------------------------------------------------------------
  void INCIXY (int ixy) {
    int val16;
    int prev;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    this.asmInstr = "INC " + ixyName;
    this.setPMTRpCycles(2, 2, 10, 1, 0);
    prev = this.getReg16Val(this.reg.IXpos + ixy);
    val16 = prev + 1;
    this.setReg16Val(this.reg.IXpos + ixy, val16);
    this.comment = "Increments 16b register " + ixyName + "; valeur= " + this.hex4(val16) + "; Flags untouched";
  }

  // -----------------------------------------------------------------------------------------------------
  void DECIXY (int ixy) {
    int val16;
    int prev;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    this.asmInstr = "DEC " + ixyName;
    this.setPMTRpCycles(2, 2, 10, 1, 0);
    prev = this.getReg16Val(this.reg.IXpos + ixy);
    val16 = prev - 1;
    this.setReg16Val(this.reg.IXpos + ixy, val16);
    this.comment = "Decrements 16b register " + ixyName + "; valeur= " + this.hex4(val16) + "; Flags untouched";
  }
}