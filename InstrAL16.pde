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
    this.comment = "value = " + this.hex4(val16);
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
    this.comment = "value = " + this.hex4(val16);

    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeCF(cf);   
    this.reg.writeHF(hf);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADCHLs (int d) {
    int val16;
    int prev, hl, cf, hf, sf, zf;
    String dName = this.regNameD(d);
    this.asmInstr = "ADC HL, " + dName;
    this.setPMTRpCycles(2, 4, 15, 2, 0);
    hl = this.getReg16Val(this.reg.HLpos);
    if (d <= this.reg.HLpos) {
      prev = this.getReg16Val(d);
    } else {
      prev = this.reg.specialReg[this.reg.SPpos];
    }
    val16 = prev + hl + this.reg.getCF();
    cf = ((val16 & 0x10000) >> 16);
    sf = ((val16 & 0x08000) >> 15);
    hf = ((val16 & 0x01000) >> 12); // to verify
    zf = (val16 == 0) ? 1 : 0;
    this.setReg16Val(this.reg.HLpos, val16);
    this.comment = "value = " + this.hex4(val16);

    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writePVF(this.oVerflow16(val16));   
    this.reg.writeZF(zf);   
    this.reg.writeSF(sf);   
    this.reg.writeCF(cf);   
    this.reg.writeHF(hf);
  }

  // -----------------------------------------------------------------------------------------------------
  void SBCHLs (int d) {
    int val16;
    int prev, hl, cf, hf, sf, zf;
    String dName = this.regNameD(d);
    this.asmInstr = "SBC HL, " + dName;
    this.setPMTRpCycles(2, 4, 15, 2, 0);
    hl = this.getReg16Val(this.reg.HLpos);
    if (d <= this.reg.HLpos) {
      prev = this.getReg16Val(d);
    } else {
      prev = this.reg.specialReg[this.reg.SPpos];
    }
    val16 = prev + hl + this.reg.getCF();
    cf = ((val16 & 0x10000) >> 16);
    sf = ((val16 & 0x08000) >> 15);
    hf = ((val16 & 0x01000) >> 12); // to verify
    zf = (val16 == 0) ? 1 : 0;
    this.setReg16Val(this.reg.HLpos, val16);
    this.comment = "value = " + this.hex4(val16);

    this.reg.setFlagBit(this.reg.NFpos);
    this.reg.writePVF(this.oVerflow16(val16));   
    this.reg.writeZF(zf);   
    this.reg.writeSF(sf);   
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
    this.comment = "value = " + this.hex4(val16);
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
    this.comment = "value = " + this.hex4(val16);
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
    this.comment = "value = " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void ADDIXYpp (int ixy, int p) {
    int val16;
    int prev;
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];
    String dName;
    if (p == this.reg.HLpos) {
      val16 = this.getReg16Val(this.reg.IXpos + ixy);
      dName = this.reg.reg16Name[this.reg.IXpos + ixy];
    } else if (p == this.reg.AFpos) {
      val16 = this.reg.specialReg[this.reg.SPpos];
      dName = this.reg.speRegName[this.reg.SPpos];
    } else {
      val16 = this.getReg16Val(p);
      dName = this.reg.reg16Name[p];
    }
    this.asmInstr = "ADD " + ixyName + ", " + dName;
    this.setPMTRpCycles(2, 4, 15, 2, 0);
    prev = this.getReg16Val(this.reg.IXpos + ixy);
    int resval16 = val16 + prev;
    this.setReg16Val(this.reg.IXpos + ixy, resval16);
    this.comment = "Value = " + this.hex4(resval16);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeCF(this.carry(val16, prev));   
    this.reg.writeHF(this.halfCarry(((prev & 0xFF00) >> 8), ((val16 & 0xFF00) >> 8)));
  }
}