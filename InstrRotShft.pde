/*###############################################################
 #
 # Rotate and Shift Group
 #
 + RLCA
 + RLA
 + RRCA
 + RRA
 # RLC r
 # RLC (HL)
 # RLC (IX+d)
 # RLC (IY+d)
 # RLC (IX+d),r
 # RLC (IY+d),r
 # RL r
 # RL (HL)
 # RRC r
 # RRC (HL)
 # RR r
 # RR (HL)
 # SLA
 # SLA (HL)
 # SLL
 # SLL (HL)
 # SRA r
 # SRA (HL)
 # SRL  r
 # SRL (HL)
 # RLD
 # RRD
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
      a = ((preva << 1) & 0xFF) | c;
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
      a = ((preva << 1) & 0xFF) | prevc;
      break;
    default:  // RRA
      this.asmInstr = "RRA";
      this.comment = "Rotate Right Circular of Accumulator and Carry";
      c = (preva & 0x01);
      a = ((preva >> 1) & 0x7F) | (prevc << 7);
    }
    this.setRegVal(this.reg.Apos, a);

    this.reg.writeCF(c);
    this.reg.writeFlagBit(this.reg.XFpos, ((a >> this.reg.XFpos) & 0x01));
    this.reg.writeFlagBit(this.reg.YFpos, ((a >> this.reg.YFpos) & 0x01));
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
  }
}