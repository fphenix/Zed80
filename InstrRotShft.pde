/*###############################################################
 #
 # Rotate and Shift Group
 #
 + RLCA
 + RLA
 + RRCA
 + RRA
 + RLC r
 + RLC (HL)
 + RL r
 + RL (HL)
 + RRC r
 + RRC (HL)
 + RR r
 + RR (HL)
 + SLA
 + SLA (HL)
 + SLL
 + SLL (HL)
 + SRA r
 + SRA (HL)
 + SRL  r
 + SRL (HL)
 # RLC (IX+d)
 # RLC (IY+d)
 # RLC (IX+d),r
 # RLC (IY+d),r
 + RLD
 + RRD
 #
 ###############################################################*/

class InstrRotShft extends InstrGPACC {

  // -----------------------------------------------------------------------------------------------------
  void RandSA (int mode) {
    int c, prevc;
    int a, preva;
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    prevc = this.reg.getCF();
    preva = this.getRegVal(this.reg.Apos);
    switch (mode) {
    case 0: // RLCA
      this.asmInstr = "RLCA";
      this.comment = "Rotate Left Circular of Accumulator, Set b7 to Carry";
      c = ((preva & 0x80) >> 7);
      a = ((preva << 1) & 0xFE) | c;
      break;
    case 1: // RRCA
      this.asmInstr = "RRCA";
      this.comment = "Rotate Right Circular of Accumulator, Set b0 to Carry";
      c = (preva & 0x01);
      a = ((preva >> 1) & 0x7F) | (c << 7);
      break;
    case 2:  // RLA
      this.asmInstr = "RLA";
      this.comment = "Rotate Left Circular of Accumulator and Carry";
      c = ((preva & 0x80) >> 7);
      a = ((preva << 1) & 0xFE) | prevc;
      break;
    default:  // RRA
      this.asmInstr = "RRA";
      this.comment = "Rotate Right Circular of Accumulator and Carry";
      c = (preva & 0x01);
      a = ((preva >> 1) & 0x7F) | (prevc << 7);
    }
    this.setRegVal(this.reg.Apos, a);
    this.comment += "; A = " + hex2(a) + "; Carry = " + c;

    this.reg.writeCF(c);
    this.reg.writeFlagBit(this.reg.XFpos, ((a >> this.reg.XFpos) & 0x01));
    this.reg.writeFlagBit(this.reg.YFpos, ((a >> this.reg.YFpos) & 0x01));
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
  }

  // -----------------------------------------------------------------------------------------------------
  void RandSr (int mode, int r) {
    int c = 0;
    int prevc;
    int hl = 0;
    int val8 = 0;
    int preval8;
    String rName = this.regNameRS(r);
    prevc = this.reg.getCF();
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(2, 4, 15, 2, 0);
      hl = this.getReg16Val(this.reg.HLpos);
      preval8 = this.getFromPointer(hl);
    } else {
      this.setPMTRpCycles(2, 2, 8, 2, 0);
      preval8 = this.getRegVal(r);
    }
    switch (mode) {
    case 0 :  // RLC
      this.asmInstr = "RLC " + rName;
      this.comment = "Rotate Left Circular; Set b7 to Carry";
      c = ((preval8 & 0x80) >> 7); // Carry = prev-bit7
      val8 = ((preval8 << 1) & 0xFE) | c;
      break;
    case 1 :  // RRC
      this.asmInstr = "RRC " + rName;
      this.comment = "Rotate Right Circular; Set b0 to Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F) | (c << 7);
      break;
    case 2 : // RL
      this.asmInstr = "RL " + rName;
      this.comment = "Rotate Left and Carry";
      c = ((preval8 & 0x80) >> 7);
      val8 = ((preval8 << 1) & 0xFE) | prevc;
      break;
    case 3 : // RR
      this.asmInstr = "RR " + rName;
      this.comment = "Rotate Right and Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F) | (prevc << 7);
      break;
    case 4 :  // SLA
      this.asmInstr = "SLA " + rName;
      this.comment = "Shift Left Arithmetic; b0 reset, Set b7 to Carry";
      c = ((preval8 & 0x80) >> 7); // Carry = prev-bit7
      val8 = ((preval8 << 1) & 0xFE);
      break;
    case 5 :  // SRA
      this.asmInstr = "SRA " + rName;
      this.comment = "Shift Right Circular; bit7 unchanged, Set b0 to Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F) | (preval8 & 0x80);
      break;
    case 6 :  // SLL aka SL1
      this.asmInstr = "SLL/SL1 " + rName;
      this.comment = "Shift Left with 1; b0 set, Set b7 to Carry";
      c = ((preval8 & 0x80) >> 7); // Carry = prev-bit7
      val8 = ((preval8 << 1) & 0xFE) | 0x01;
      break;
    case 7 :  // SRL
      this.asmInstr = "SRL " + rName;
      this.comment = "Shift Right Logical; bit 7 reset, Set b0 to Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F);
      break;
    default:
      println("BUG!");
    }

    if (r == this.reg.contHLpos) {
      this.putInPointer(hl, val8);
    } else {
      this.setRegVal(r, val8);
    }
    this.comment += "; Value = " + hex2(val8) + "; Carry = " + c;
    this.setFlagsRotType(val8, c);
  }

  // -----------------------------------------------------------------------------------------------------
  void RlrD (int lr) {
    int hl;
    int val8, a;
    int preval8, preva;
    this.setPMTRpCycles(2, 5, 18, 2, 0);
    hl = this.getReg16Val(this.reg.HLpos);
    preval8 = this.getFromPointer(hl);
    preva = this.getRegVal(this.reg.Apos);
    if (lr == 1) {
      // RLD : ED 6F
      this.asmInstr = "RLD";
      val8 = ((preval8 & 0x0F) << 4) | (preva & 0x0F);
      a = (preva & 0xF0) | ((preval8 & 0xF0) >> 4);
      this.comment = "Rotate Left Nibbles A and (HL)";
      this.comment += "; A = " + hex2(a) + "; (HL) = " + hex2(val8);
    } else {
      // RRD : ED 67
      this.asmInstr = "RRD";
      val8 = ((preva & 0x0F) << 4) | ((preval8 & 0xF0) >> 4);  /* Fixed 26/03/2024 */
      a = (preva & 0xF0) | (preval8 & 0x0F);
      this.comment = "Rotate Right Nibbles A and (HL)";
      this.comment += "; A = " + hex2(a) + "; (HL) = " + hex2(val8);
    }
    this.putInPointer(hl, val8);
    this.setRegVal(this.reg.Apos, a);
    this.setFlagsRotType(val8, this.reg.getCF());
  }

  // -----------------------------------------------------------------------------------------------------
  void RandSIXY (int mode, int ixy, int r, int twoscomp) {
    int c = 0;
    int prevc;
    int mem16 = 0;
    int val8 = 0;
    int preval8;
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy] + sign + abs(displacement);    
    String rName = this.regNameRS(r);
    this.setPMTRpCycles(4, 6, 23, 4, 1);
    prevc = this.reg.getCF();
    mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    preval8 = this.getFromPointer(mem16);
    switch (mode) {
    case 0 :  // RLC
      this.asmInstr = "RLC";
      this.comment = "Rotate Left Circular; Set b7 to Carry";
      c = ((preval8 & 0x80) >> 7); // Carry = prev-bit7
      val8 = ((preval8 << 1) & 0xFE) | c;
      break;
    case 1 :  // RRC
      this.asmInstr = "RRC";
      this.comment = "Rotate Right Circular; Set b0 to Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F) | (c << 7);
      break;
    case 2 : // RL
      this.asmInstr = "RL";
      this.comment = "Rotate Left and Carry";
      c = ((preval8 & 0x80) >> 7);
      val8 = ((preval8 << 1) & 0xFE) | prevc;
      break;
    case 3 : // RR
      this.asmInstr = "RR";
      this.comment = "Rotate Right and Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F) | (prevc << 7);
      break;
    case 4 :  // SLA
      this.asmInstr = "SLA";
      this.comment = "Shift Left Arithmetic; b0 reset, Set b7 to Carry";
      c = ((preval8 & 0x80) >> 7); // Carry = prev-bit7
      val8 = ((preval8 << 1) & 0xFE);
      break;
    case 5 :  // SRA
      this.asmInstr = "SRA";
      this.comment = "Shift Right Circular; bit7 unchanged, Set b0 to Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F) | (preval8 & 0x80);
      break;
    case 6 :  // SLL aka SL1
      this.asmInstr = "SLL/SL1";
      this.comment = "Shift Left with 1; b0 set, Set b7 to Carry";
      c = ((preval8 & 0x80) >> 7); // Carry = prev-bit7
      val8 = ((preval8 << 1) & 0xFE) | 0x01;
      break;
    case 7 :  // SRL
      this.asmInstr = "SRL";
      this.comment = "Shift Right Logical; bit 7 reset, Set b0 to Carry";
      c = (preval8 & 0x01);
      val8 = ((preval8 >> 1) & 0x7F);
      break;
    default:
      println("BUG!");
    }
    this.asmInstr += " (" + ixyName + ")";
    this.comment += "; Value = " + hex2(val8) + "; Carry = " + c;
    this.putInPointer(mem16, val8);
    if (r != 6) {
      this.setRegVal(r, val8);
      this.asmInstr += ", " + rName;
    }
    this.setFlagsRotType(val8, c);
  }
}
