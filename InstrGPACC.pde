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
  private boolean isInRange (int val, int low, int high) {
    if (low > high) {
      return isInRange(val, high, low);
    } else {
      return ((val >= low) && (val <= high));
    }
  }

  private boolean isIn (int hval, int hlow, int hhigh, int lval, int llow, int lhigh) {
    return (this.isInRange(hval, hlow, hhigh) && this.isInRange(lval, llow, lhigh));
  }

  // -----------------------------------------------------------------------------------------------------
  void DAA () {
    int n; // N flag
    int ch; // C and H flags
    this.asmInstr = "DAA";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    int a;
    int preva =  this.getRegVal(this.reg.Apos);
    int ha = (preva & 0xF0) >> 4;
    int la = (preva & 0x0F) >> 0;
    int c = 0;
    int h = 0;
    int toadd = 0;
    n  = this.reg.getFlagBit(this.reg.NFpos) ; // N=0 si ADD, ADC, INC; N=1 si SUB, SBC, NEG, DEC
    ch  = this.reg.getFlagBit(this.reg.CFpos) << 1;
    ch += this.reg.getFlagBit(this.reg.HFpos) << 0;

    // new C flag and value to add to A
    // new H flag
    if (n == 0) { // N=0
      switch (ch) {
      case 0x0 : // N=0, C=0, H=0
        if (this.isIn(ha, 0x0, 0x9, la, 0x0, 0x9)) {  
          toadd = 0x00;  
          c = 0;
        } else if (this.isIn(ha, 0x0, 0x8, la, 0xA, 0xF)) {  
          toadd = 0x06;  
          c = 0;
        } else if (this.isIn(ha, 0xA, 0xF, la, 0x0, 0x9)) {  
          toadd = 0x60;  
          c = 1;
        } else if (this.isIn(ha, 0x9, 0xF, la, 0xA, 0xF)) {  
          toadd = 0x66;  
          c = 1;
        }
        break;
      case 0x1 : // N=0, C=0, H=1
        if (this.isIn(ha, 0x0, 0x9, la, 0x0, 0x3)) {  
          toadd = 0x06;  
          c = 0;
        } else if (this.isIn(ha, 0xA, 0xF, la, 0x0, 0x3)) {  
          toadd = 0x66;  
          c = 1;
        }
        break;
      case 0x2 : // N=0, C=1, H=0
        if (this.isIn(ha, 0x0, 0x2, la, 0x0, 0x9)) {  
          toadd = 0x60;  
          c = 1;
        } else if (this.isIn(ha, 0x0, 0x2, la, 0xA, 0xF)) {  
          toadd = 0x66;  
          c = 1;
        }
        break;
      default : // N=0, C=1, H=1
        if (this.isIn(ha, 0x0, 0x3, la, 0x0, 0x3)) {  
          toadd = 0x66;  
          c = 1;
        }
      }
      if (this.isInRange(la, 0x0, 0x9)) {
        h = 0;
      } else {
        h = 1;
      }
    } else { // N=1
      switch (ch) {
      case 0x0 : // N=1, C=0, H=0
        if (this.isIn(ha, 0x0, 0x9, la, 0x0, 0x9)) {  
          toadd = 0x00;  
          c = 0;
        }      
        break;
      case 0x1: // N=1, C=0, H=1
        if (this.isIn(ha, 0x0, 0x8, la, 0x6, 0xF)) {  
          toadd = 0xFA;  
          c = 0;
        }
        break;
      case 0x2 : // N=1, C=1, H=0
        if (this.isIn(ha, 0x7, 0xF, la, 0x0, 0x9)) {  
          toadd = 0xA0;  
          c = 1;
        }      
        break;
      default : // N=1, C=1, H=1
        if (this.isIn(ha, 0x6, 0xF, la, 0x6, 0xF)) {  
          toadd = 0x9A;  
          c = 1;
        }
      }
      if  ((ch & 0x1) == 0x00) { // H=0
        h = 0;
      } else { // H=1
        if (this.isInRange(la, 0x0, 0x5)) {
          h = 1;
        } else {
          h = 0;
        }
      }
    }
    a = (preva + this.twoComp2signed(toadd)) & 0xFF;  

    this.setRegVal(this.reg.Apos, a);

    this.comment = "Decimal Adjust after Addition (or Sub!) : Accumulator is Binary-Coded-Decimal corrected to " + hex2(a);

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(a, this.reg.SFpos, 0x01);
    zf = this.isZero(a); 
    yf = this.rshiftMask(a, this.reg.YFpos, 0x01);
    hf = h;
    xf = this.rshiftMask(a, this.reg.XFpos, 0x01);
    pvf = this.parity(a);
    nf = n;
    cf = c;
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

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
      this.asmInstr = "DI"; // 0xF3
      this.reg.IFF1 = 0;
      this.reg.IFF2 = 0;
      this.comment = "Dis";
    } else {
      this.asmInstr = "EI"; // 0xFB
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
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void NEG () {
    this.asmInstr = "NEG";
    this.setPMTRpCycles(2, 2, 8, 1, 0);
    int preva = this.getRegVal(this.reg.Apos);
    int a =  0x100 - preva;
    this.setRegVal(this.reg.Apos, a);
    this.comment = "Negate A (change sign); A=" + hex2(a);
    this.setFlagsSubType(a, preva, 0);
  }

  // -----------------------------------------------------------------------------------------------------
  void HALT () {
    this.asmInstr = "HALT";
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    this.comment = "Wait until an interrupt or reset is accepted (CPU is halted), does NOP in the meantime";
    if ((this.pin.RESET_b | this.pin.INT_b | this.pin.NMI_b) == 0) {
      this.setPMTRpCycles(-1, 1, 4, 1, 0);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
    }
  }

  // -----------------------------------------------------------------------------------------------------
  void IMm (int m) {
    this.asmInstr = "IM " + m;
    this.setPMTRpCycles(2, 2, 8, 1, 0);
    this.comment = "Set Interrupt Mode " + m;
    this.reg.IM = m & 0x03;
  }
}