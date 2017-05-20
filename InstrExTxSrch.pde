/*###############################################################
 #
 #  Exchange, Block Transfert, Block Search Group
 #
 + EX DE,HL
 + EX AF,AF'
 + EXX
 + EX (SP),HL
 + EX (SP),IX
 + EX (SP),IY
 + LDI
 + LDIR
 + LDD
 + LDDR
 + CPI
 + CPIR
 + CPD
 + CPDR
 #
 ###############################################################*/

class InstrExTxSrch extends InstrStack {

  // -----------------------------------------------------------------------------------------------------
  void EXDEHL () {
    this.asmInstr = "EX DE, HL";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    this.swapReg(this.reg.Dpos, this.reg.Hpos);
    this.swapReg(this.reg.Epos, this.reg.Lpos);
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void EXcontSPHL () {
    int memPointer = this.reg.specialReg[this.reg.SPpos];
    int vall = this.mem.peek(memPointer + this.reg.LSB);
    int valh = this.mem.peek(memPointer + this.reg.MSB);
    this.asmInstr = "EX (SP), HL";
    this.setPMTRpCycles(1, 5, 19, 1, 0);
    this.mem.poke(memPointer + this.reg.LSB, this.getRegVal(this.reg.Lpos));
    this.mem.poke(memPointer + this.reg.MSB, this.getRegVal(this.reg.Hpos));
    this.setRegVal(this.reg.Hpos, valh);
    this.setRegVal(this.reg.Lpos, vall);
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void EXcontSPIXY (int ixy) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int memPointer = this.reg.specialReg[this.reg.SPpos];
    int vall = this.mem.peek(memPointer + 0);
    int valh = this.mem.peek(memPointer + 1);
    this.asmInstr = "EX (SP), " + ixyName;
    this.setPMTRpCycles(2, 6, 23, 1, 0);
    int r16 = this.getReg16Val(this.reg.IXpos + ixy);
    this.mem.poke(memPointer + 0, this.rshiftMask(r16, 0, 0xFF)); // LSB
    this.mem.poke(memPointer + 1, this.rshiftMask(r16, 8, 0xFF)); // MSB
    this.setReg16Val(this.reg.IXpos + ixy, (valh << 8) + vall);
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void EXAFAFp () {
    this.asmInstr = "EX AF, A\'F\'";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    this.swapPrime(this.reg.Apos);
    this.swapPrime(this.reg.Fpos);
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void EXX () {
    this.asmInstr = "EXX";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    for (int i = this.reg.Bpos; i <= this.reg.Lpos; i++) {
      this.swapPrime(i);
    }
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDI () {
    this.asmInstr = "LDI";
    int val8 = this.getFromRegPointer(this.reg.HLpos);
    this.putInRegPointer(this.reg.DEpos, val8);
    int val16 = this.getReg16Val(this.reg.HLpos);
    val16++;
    this.setReg16Val(this.reg.HLpos, val16);
    val16 = this.getReg16Val(this.reg.DEpos);
    val16++;
    this.setReg16Val(this.reg.DEpos, val16);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    this.setPMTRpCycles(2, 4, 16, 1, 0);
    this.comment = "";

    // Flags
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }

  // -----------------------------------------------------------------------------------------------------
  void LDD () {
    this.asmInstr = "LDD";
    int val8 = this.getFromRegPointer(this.reg.HLpos);
    this.putInRegPointer(this.reg.DEpos, val8);
    int val16 = this.getReg16Val(this.reg.HLpos);
    val16--;
    this.setReg16Val(this.reg.HLpos, val16);
    val16 = this.getReg16Val(this.reg.DEpos);
    val16--;
    this.setReg16Val(this.reg.DEpos, val16);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    this.setPMTRpCycles(2, 4, 16, 1, 0);
    this.comment = "Move value " + this.hex2(val8) + " from (HL) to (DE); then decrement HL, DE and BC";

    // Flags
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }

  // -----------------------------------------------------------------------------------------------------
  void LDIR () {
    this.asmInstr = "LDIR";
    int val8 = this.getFromRegPointer(this.reg.HLpos);
    this.putInRegPointer(this.reg.DEpos, val8);
    int val16 = this.getReg16Val(this.reg.HLpos);
    val16++;
    this.setReg16Val(this.reg.HLpos, val16);
    val16 = this.getReg16Val(this.reg.DEpos);
    val16++;
    this.setReg16Val(this.reg.DEpos, val16);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    this.comment = "Repeat Move value " + this.hex2(val8) + " from (HL) to (DE); then increment HL, DE and decrement BC until BC = 0 ; BC=" + this.hex4(bc);
    if (bc == 0) {
      this.setPMTRpCycles(2, 4, 16, 1, 0);
    } else {
      this.setPMTRpCycles(-2, 5, 21, 3, 0);
    }

    // Flags
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }

  // -----------------------------------------------------------------------------------------------------
  void LDDR () {
    this.asmInstr = "LDDR";
    int val8 = this.getFromRegPointer(this.reg.HLpos);
    this.putInRegPointer(this.reg.DEpos, val8);
    int val16 = this.getReg16Val(this.reg.HLpos);
    val16--;
    this.setReg16Val(this.reg.HLpos, val16);
    val16 = this.getReg16Val(this.reg.DEpos);
    val16--;
    this.setReg16Val(this.reg.DEpos, val16);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    this.comment = "Repeat Move value "+this.hex2(val8)+" from (HL) to (DE); then decrement HL, DE and BC until BC = 0 ; BC="+this.hex4(bc);
    if (bc == 0) {
      this.setPMTRpCycles(2, 4, 16, 1, 0);
    } else {
      this.setPMTRpCycles(-2, 5, 21, 3, 0);
    }

    // Flags
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }

  // -----------------------------------------------------------------------------------------------------
  void CPI () {
    this.asmInstr = "CPI";
    int val8inconthl = this.getFromRegPointer(this.reg.HLpos);
    int val8inaccu = this.getRegVal(this.reg.Apos);
    int compa = val8inaccu - val8inconthl;
    int hl = this.getReg16Val(this.reg.HLpos);
    hl++;
    this.setReg16Val(this.reg.HLpos, hl);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    this.setPMTRpCycles(2, 4, 16, 1, 0);
    this.comment = " Compare values in A="+this.hex2(val8inaccu);
    this.comment += " and in (HL)="+this.hex2(val8inconthl);
    this.comment += "; Flags are updated; Increment HL and Decrement BC";

    // Flags
    this.reg.writeFlagBit(this.reg.SFpos, (compa & 0x80) >> 7);
    this.reg.writeFlagBit(this.reg.ZFpos, this.isZero(compa));
    this.reg.writeFlagBit(this.reg.HFpos, (compa & 0x10) >> 4);
    this.reg.setFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }

  // -----------------------------------------------------------------------------------------------------
  void CPIR () {
    this.asmInstr = "CPIR";
    int val8inconthl = this.getFromRegPointer(this.reg.HLpos);
    int val8inaccu = this.getRegVal(this.reg.Apos);
    int compa = val8inaccu - val8inconthl;
    int hl = this.getReg16Val(this.reg.HLpos);
    hl++;
    this.setReg16Val(this.reg.HLpos, hl);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    if ((bc != 0) && (compa != 0)) {
      this.setPMTRpCycles(-2, 5, 21, 3, 0);
    } else { // bc = 0 or match A = (HL)
      this.setPMTRpCycles(2, 4, 16, 1, 0);
    }
    this.comment = "Repeat Compare values in A="+this.hex2(val8inaccu);
    this.comment += " and in (HL)="+this.hex2(val8inconthl)+"; Flags are updated; Increment HL and ";
    this.comment += " Decrement BC until match or BC=0; match=" + this.isZero(compa) + " ; bc=" + this.hex4(bc);

    // Flags
    this.reg.writeFlagBit(this.reg.SFpos, (compa & 0x80) >> 7);
    this.reg.writeFlagBit(this.reg.ZFpos, this.isZero(compa));
    this.reg.writeFlagBit(this.reg.HFpos, this.halfBorrow(val8inaccu, val8inconthl));
    this.reg.setFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }

  // -----------------------------------------------------------------------------------------------------
  void CPD () {
    this.asmInstr = "CPD";
    int val8inconthl = this.getFromRegPointer(this.reg.HLpos);
    int val8inaccu = this.getRegVal(this.reg.Apos);
    int compa = val8inaccu - val8inconthl;
    int hl = this.getReg16Val(this.reg.HLpos);
    hl--;
    this.setReg16Val(this.reg.HLpos, hl);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    this.setPMTRpCycles(2, 4, 16, 1, 0);
    this.comment = "Compare values in A="+this.hex2(val8inaccu);
    this.comment += " and in (HL)="+this.hex2(val8inconthl)+"; Flags are updated;";
    this.comment += " Decrement HL="+hex4(hl)+" and BC=" + hex4(bc);

    // Flags
    this.reg.writeFlagBit(this.reg.SFpos, (compa & 0x80) >> 7);
    this.reg.writeFlagBit(this.reg.ZFpos, this.isZero(compa));
    this.reg.writeFlagBit(this.reg.HFpos, (compa & 0x10) >> 4);
    this.reg.setFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
    this.comment += "; New Flags = " + this.reg.printFlags();
  }

  // -----------------------------------------------------------------------------------------------------
  void CPDR () {
    this.asmInstr = "CPDR";
    int val8inconthl = this.getFromRegPointer(this.reg.HLpos);
    int val8inaccu = this.getRegVal(this.reg.Apos);
    int compa = val8inaccu - val8inconthl;
    int hl = this.getReg16Val(this.reg.HLpos);
    hl--;
    this.setReg16Val(this.reg.HLpos, hl);
    int bc = this.getReg16Val(this.reg.BCpos);
    bc--;
    this.setReg16Val(this.reg.BCpos, bc);
    if ((bc != 0) && (compa != 0)) {
      this.setPMTRpCycles(-2, 5, 21, 3, 0);
    } else { // bc = 0 or match A = (HL)
      this.setPMTRpCycles(2, 4, 16, 1, 0);
    }
    this.comment = "Repeat Compare values in A="+this.hex2(val8inaccu);
    this.comment += " and in (HL)="+this.hex2(val8inconthl)+"; Flags are updated; Decrement HL and BC";
    this.comment += " until match or BC=0; match=" + this.isZero(compa) + " ; bc=" + this.hex4(bc);

    // Flags
    this.reg.writeFlagBit(this.reg.SFpos, (compa & 0x80) >> 7);
    this.reg.writeFlagBit(this.reg.ZFpos, this.isZero(compa));
    this.reg.writeFlagBit(this.reg.HFpos, (compa & 0x10) >> 4);
    this.reg.setFlagBit(this.reg.NFpos);
    this.reg.writeFlagBit(this.reg.PVFpos, this.isNotZero16(bc));
  }
}