/*############################################################### //<>//
 #
 # General-Purpose Arithmetic and CPU Control Group
 #
 # DAA
 + CPL
 + NEG
 + CCF
 + SCF
 + NOP
 + HALT
 + DI
 + EI
 # IM m
 #
 ###############################################################*/

public class InstrGPACC extends InstrIO {

  // -----------------------------------------------------------------------------------------------------
  void CPL () {
    this.asmInstr = "CPL";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    int a =  0xFF ^ this.getRegVal(this.reg.Apos);
    this.setRegVal(this.reg.Apos, a);

    this.reg.writeFlagBit(this.reg.XFpos, ((a >> this.reg.XFpos) & 0x01));
    this.reg.writeFlagBit(this.reg.YFpos, ((a >> this.reg.YFpos) & 0x01));
    this.reg.setFlagBit(this.reg.HFpos);
    this.reg.setFlagBit(this.reg.NFpos);
    this.comment = "Complement Accumulator (invert all bits like a A xor 0xFF)";
  }

  // -----------------------------------------------------------------------------------------------------
  void CCF () {
    this.asmInstr = "CCF";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    int a = this.getRegVal(this.reg.Apos);

    this.reg.writeFlagBit(this.reg.XFpos, ((a >> this.reg.XFpos) & 0x01));
    this.reg.writeFlagBit(this.reg.YFpos, ((a >> this.reg.YFpos) & 0x01));
    this.reg.toggleFlagBit(this.reg.CFpos);
    //this.reg.resetFlagBit(this.reg.HFpos); // could be anything...
    this.reg.resetFlagBit(this.reg.NFpos);
    this.comment = "Complement (Invert) Carry Flag";
  }

  // -----------------------------------------------------------------------------------------------------
  void SCF () {
    this.asmInstr = "SCF";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    int a = this.getRegVal(this.reg.Apos);

    this.reg.writeFlagBit(this.reg.XFpos, ((a >> this.reg.XFpos) & 0x01));
    this.reg.writeFlagBit(this.reg.YFpos, ((a >> this.reg.YFpos) & 0x01));
    this.reg.setFlagBit(this.reg.CFpos);
    this.reg.resetFlagBit(this.reg.HFpos);
    this.reg.resetFlagBit(this.reg.NFpos);
    this.comment = "Set Carry Flag";
  }

  // -----------------------------------------------------------------------------------------------------
  void EIDI (int enable) {
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    if (enable == 0) {
      this.asmInstr = "DI";
      this.reg.IFF1 = 0;
      this.reg.IFF2 = 0;
      this.comment = "Dis";
    } else {
      this.asmInstr = "EI";
      this.reg.IFF1 = 1;
      this.reg.IFF2 = 1;
      this.comment = "En";
    }
    this.comment += "able Interrupts";
  }

  // -----------------------------------------------------------------------------------------------------
  void NOP () {
    this.asmInstr = "NOP";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    this.comment = "No-Operation";
  }

  // -----------------------------------------------------------------------------------------------------
  void NEG () {
    this.asmInstr = "NEG";
    this.setPMTRpCycles(2, 2, 8, 1, 0);
    int preva = this.getRegVal(this.reg.Apos);
    int a =  0x100 - preva;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "Negate A (change sign)";

    // Flags : S Z y H x PV N C
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = this.rshiftMask(a, this.reg.HFpos, 0x01);
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.oVerflow(preva, a, preva-a);
    nf = 1;
    cf = this.borrow(preva, a);
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void HALT () {
    this.asmInstr = "HALT";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    this.comment = "Wait until an interrupt or reset is accepted (CPU is halted), does NOP in the meantime";
    /*
    while (reset || int || nmi) {
     this.NOP();
     }
     */
  }
}