/*###############################################################
 #
 #  8-Bit Load Group
 #
 + LD r,s
 # LD pt,ps
 # LD qt,qs
 + LD r,n
 # LD p,n
 # LD q,n
 + LD r,(HL)
 # LD r,(IX+d)
 # LD r,(IY+d)
 + LD (HL),r
 # LD (IX+d),r
 # LD (IY+d),r
 # LD (HL),n
 # LD (IX+d),n
 # LD (IY+d),n
 # LD A,(BC)
 # LD A,(DE)
 # LD A,(nn)
 # LD (BC),A
 # LD (DE),A
 # LD (nn),A
 # LD A,I
 # LD A,R
 # LD I,A
 # LD R,A
 #
 ###############################################################*/

class InstrLD8 extends InstrLD16 {

  // -----------------------------------------------------------------------------------------------------
  void LDrs (int r, int s) {
    String rName = this.regNameRS(r);
    String sName = this.regNameRS(s); 
    this.asmInstr = "LD " + rName + ", " + sName;
    this.setPMTRpCycles(1, 1, 4, 1, 0);
    this.setRegVal(r, this.getRegVal(s));
    this.comment = "Value in register source " + sName + " (";
    this.comment += this.hex2(this.getRegVal(r)) + ") copied into register " + rName;
  }

  // -----------------------------------------------------------------------------------------------------
  void LDrval (int r, int val8) {
    String rName = this.regNameRS(r);
    this.asmInstr = "LD " + rName + ", " + this.hex2(val8);
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(2, 3, 10, 1, 1);
    } else {
      this.setPMTRpCycles(2, 2, 7, 1, 1);
    }
    this.comment = "Value " + this.hex2(val8) + " loaded into ";
    if (r == this.reg.contHLpos) {
      int hl = this.getReg16Val(this.reg.HLpos);
      this.putInRegPointer(this.reg.HLpos, val8);
      this.comment += "memory address pointed by " + rName + " (" + this.hex4(hl) + ")";
    } else {
      this.setRegVal(r, val8);
      this.comment += "register " + rName;
    }
  }

  // -----------------------------------------------------------------------------------------------------
  void LDinContentHL (int s) {
    String rName = this.regNameRS(this.reg.contHLpos);
    String sName = this.regNameRS(s); 
    this.asmInstr = "LD " + rName + ", " + sName;
    this.setPMTRpCycles(1, 2, 7, 1, 0);
    int hl = this.getReg16Val(this.reg.HLpos);
    this.putInRegPointer(this.reg.HLpos, this.getRegVal(s));
    this.comment = "Value in register source " + sName + " (" + this.hex2(this.getRegVal(s));
    this.comment += ") copied into memory address pointed by " + rName + " (" + this.hex4(hl) + ")";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDfromContentHL (int r) {
    String rName = this.regNameRS(r);
    String sName = this.regNameRS(this.reg.contHLpos);
    this.asmInstr = "LD " + rName + ", " + sName;
    this.setPMTRpCycles(1, 2, 7, 1, 0);
    int hl = this.getReg16Val(this.reg.HLpos);
    this.setRegVal(r, this.getFromPointer(hl));
    this.comment = "Value at addr contained in " + sName + " (" + this.hex4(hl);
    this.comment += ": " + this.getRegVal(r) + ") copied into register " + rName;
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAcontval (int memlow, int memhigh) {
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "LD A, (" + this.hex4(mem16) + ")";
    this.setPMTRpCycles(3, 4, 13, 1, 2);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Load A with content of addr " + this.hex4(mem16) + ", value " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAcontd (int d) {
    String dName = this.regNameD(d);
    int mem16 = this.getReg16Val(d);
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "LD A, (" + dName + ")";
    this.setPMTRpCycles(3, 4, 13, 1, 2);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Load A with content of (" + dName + "), value " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDrcontIXYtc (int r, int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    String rName = this.regNameRS(r);
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "LD " + rName + ", (" + ixyName + sign + abs(displacement) + ")";
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getFromPointer(mem16);
    this.setRegVal(r, val8);
    this.comment = "Load " + rName + " with value " + this.hex2(val8);
    this.comment += " at memory addr " + ixyName + sign + abs(displacement);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontIXYtcr (int r, int ixy, int twoscomp) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    String rName = this.regNameRS(r);
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "LD (" + ixyName + sign + abs(displacement) + "), " + rName;
    this.setPMTRpCycles(3, 5, 19, 2, 1);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    int val8 = this.getRegVal(r);
    this.putInPointer(mem16, val8);
    this.comment = "Load memory addr " + ixyName + sign + abs(displacement) + " with value ";
    this.comment += this.hex2(val8) + " in " + rName;
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontIXYtcval (int ixy, int twoscomp, int val8) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int displacement = this.twoComp2signed(twoscomp);
    String sign = (displacement < 0) ? "-" : "+";
    this.asmInstr = "LD (" + ixyName + sign + abs(displacement) + "), " + this.hex2(val8);
    this.setPMTRpCycles(4, 5, 19, 2, 2);
    int mem16 = this.getReg16Val(this.reg.IXpos + ixy) + displacement;
    this.putInPointer(mem16, val8);
    this.comment = "Load memory addr " + ixyName + sign + abs(displacement) + " with value " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAI () {
    int val8 = this.getRegVal(this.reg.Ipos);
    this.asmInstr = "LD A, I";
    this.setPMTRpCycles(2, 2, 9, 2, 0);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Load A with I, value " + this.hex2(val8);

    //Flags
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(val8, this.reg.SFpos, 0x01);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.reg.IFF2;
    nf = 0;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAR () {
    int val8 = this.getRegVal(this.reg.Rpos);
    this.asmInstr = "LD A, R";
    this.setPMTRpCycles(2, 2, 9, 2, 0);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Load A with R, value " + this.hex2(val8);

    //Flags
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(val8, this.reg.SFpos, 0x01);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.reg.IFF2;
    nf = 0;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDIA () {
    int val8 = this.getRegVal(this.reg.Apos);
    this.asmInstr = "LD I, A";
    this.setPMTRpCycles(2, 2, 9, 2, 0);
    this.setRegVal(this.reg.Ipos, val8);
    this.comment = "Load I with A, value " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDRA () {
    int val8 = this.getRegVal(this.reg.Apos);
    this.asmInstr = "LD R, A";
    this.setPMTRpCycles(2, 2, 9, 2, 0);
    this.setRegVal(this.reg.Rpos, val8);
    this.comment = "Load R with A, value " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontvalA (int memlow, int memhigh) {
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    this.asmInstr = "LD (" + this.hex4(mem16) + "), A";
    this.setPMTRpCycles(3, 4, 13, 1, 2);
    int val8 = this.getRegVal(this.reg.Apos);
    this.putInPointer(mem16, val8);
    this.comment = "Load content of addr " + this.hex4(mem16) + ", value " + this.hex2(val8) + ", in A";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontdA (int d) {
    String dName = this.regNameD(d);
    int mem16 = this.getReg16Val(d);
    this.asmInstr = "LD (" + dName + "), A";
    this.setPMTRpCycles(3, 4, 13, 1, 2);
    int val8 = this.getRegVal(this.reg.Apos);
    this.putInPointer(mem16, val8);
    this.comment = "Load content of addr (" + dName + "), value " + this.hex2(val8) + ", in A";
  }
}