/*###############################################################
 #
 #  8-Bit Load Group
 #
 + LD r,s
 + LD r,(HL)
 + LD (HL),r
 # LD pt,ps
 # LD qt,qs
 + LD r,n
 # LD (HL),n
 # LD p,n
 # LD q,n
 # LD r,(IX+d)
 # LD r,(IY+d)
 # LD (IX+d),r
 # LD (IY+d),r
 # LD (IX+d),n
 # LD (IY+d),n
 # LD A,(BC)
 # LD A,(DE)
 # LD A,(nn)
 # LD (BC),A
 # LD (DE),A
 # LD (nn),A
 + LD A,I
 + LD A,R
 + LD I,A
 + LD R,A
 #
 ###############################################################*/

class InstrLD8 extends InstrLD16 {

  // -----------------------------------------------------------------------------------------------------
  void LDrs (int r, int s) {
    String rName = this.regNameRS(r);
    String sName = this.regNameRS(s); 
    int hl = 0, sval = 0;
    this.asmInstr = "LD " + rName + ", " + sName;
    if (r == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      hl = this.getReg16Val(this.reg.HLpos);
      sval = this.getRegVal(s);
      this.putInRegPointer(this.reg.HLpos, sval);
    } else if (s == this.reg.contHLpos) {
      this.setPMTRpCycles(1, 2, 7, 1, 0);
      hl = this.getReg16Val(this.reg.HLpos);
      sval = this.getFromPointer(hl);
      this.setRegVal(r, sval);
    } else {
      this.setPMTRpCycles(1, 1, 4, 1, 0);
      sval = this.getRegVal(s);
      this.setRegVal(r, sval);
    }
    this.comment = "Value = " + this.hex2(sval);
  }

  void LDinContentHL (int s) {
    this.LDrs(this.reg.contHLpos, s);
  }

  void LDfromContentHL (int r) {
    this.LDrs(r, this.reg.contHLpos);
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
    if (r == this.reg.contHLpos) {
      //int hl = this.getReg16Val(this.reg.HLpos);
      this.putInRegPointer(this.reg.HLpos, val8);
    } else {
      this.setRegVal(r, val8);
    }
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAcontval (int memlow, int memhigh) {
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "LD A, (" + this.hex4(mem16) + ")";
    this.setPMTRpCycles(3, 4, 13, 1, 2);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Value " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAcontd (int d) {
    String dName = this.regNameD(d);
    int mem16 = this.getReg16Val(d);
    int val8 = this.getFromPointer(mem16);
    this.asmInstr = "LD A, (" + dName + ")";
    this.setPMTRpCycles(1, 2, 7, 1, 0);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Value " + this.hex2(val8);
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
    this.comment = "Value = " + this.hex2(val8);
    this.comment += "; displacement = " + sign + abs(displacement);
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
    this.comment = "Value = " + this.hex2(val8);
    this.comment += "; displacement = " + sign + abs(displacement);
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
    this.comment = "Value = " + this.hex2(val8);
    this.comment += "; displacement = " + sign + abs(displacement);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDAI () {
    int val8 = this.getRegVal(this.reg.Ipos);
    this.asmInstr = "LD A, I";
    this.setPMTRpCycles(2, 2, 9, 2, 0);
    this.setRegVal(this.reg.Apos, val8);
    this.comment = "Value = " + this.hex2(val8);

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
    this.comment = "Value = " + this.hex2(val8);

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
    this.comment = "Value = " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDRA () {
    int val8 = this.getRegVal(this.reg.Apos);
    this.asmInstr = "LD R, A";
    this.setPMTRpCycles(2, 2, 9, 1, 0);
    this.setRegVal(this.reg.Rpos, val8);
    this.comment = "Value = " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontvalA (int memlow, int memhigh) {
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    this.asmInstr = "LD (" + this.hex4(mem16) + "), A";
    this.setPMTRpCycles(3, 4, 13, 1, 2);
    int val8 = this.getRegVal(this.reg.Apos);
    this.putInPointer(mem16, val8);
    this.comment = "Value = " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontdA (int d) {
    String dName = this.regNameD(d);
    int mem16 = this.getReg16Val(d);
    this.asmInstr = "LD (" + dName + "), A";
    this.setPMTRpCycles(1, 2, 7, 1, 0);
    int val8 = this.getRegVal(this.reg.Apos);
    this.putInPointer(mem16, val8);
    this.comment = "Value = " + this.hex2(val8);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDpp (int ixy, int pr, int ps) {
    if ( ((pr <= this.reg.Epos) || (pr == this.reg.Apos)) && 
      ((ps <= this.reg.Epos) || (ps == this.reg.Apos)) ) {
      this.LDrs(pr, ps);
    } else {
      int val8;
      int val16;
      String rName, sName;
      if (ps == this.reg.IXYhpos) {
        sName = this.reg.reg16Name[this.reg.IXpos + ixy] + "h";
        val8 = (this.getReg16Val(this.reg.IXpos + ixy) & 0xFF00) >> 8;
      } else if (ps == this.reg.IXYlpos) {
        sName = this.reg.reg16Name[this.reg.IXpos + ixy] + "l";
        val8 = (this.getReg16Val(this.reg.IXpos + ixy) & 0x00FF) >> 0;
      } else {
        sName = this.reg.regName[ps];
        val8 = this.getRegVal(ps);
      }
      if (pr == this.reg.IXYhpos) {
        rName = this.reg.reg16Name[this.reg.IXpos + ixy] + "h";
        val16 = this.getReg16Val(this.reg.IXpos + ixy);
        this.setReg16Val((this.reg.IXpos + ixy), (val16 & 0x00FF) | (val8 << 8));
      } else if (pr == this.reg.IXYlpos) {
        rName = this.reg.reg16Name[this.reg.IXpos + ixy] + "l";
        val16 = this.getReg16Val(this.reg.IXpos + ixy);
        this.setReg16Val((this.reg.IXpos + ixy), (val16 & 0xFF00) | (val8 << 0));
      } else {
        rName = this.reg.regName[pr];
        this.setRegVal(pr, val8);
      }
      this.asmInstr = "LD " + rName + ", " + sName;
    }
    this.setPMTRpCycles(2, 2, 8, 2, 0);
    this.comment = "";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDIXYhlval (int ixy, int horl, int val8) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    if (horl == 0) { // IXh or IYh
      val16 = ((val8 & 0xFF) << 8) | (val16 & 0x00FF);
      ixyName += "h";
    } else {
      val16 = (val8 & 0xFF) | (val16 & 0xFF00);
      ixyName += "l";
    }
    this.asmInstr = "LD " + ixyName + ", " + this.hex4(val16);
    this.setPMTRpCycles(3, 3, 11, 2, 1);
    this.setReg16Val(this.reg.IXpos + ixy, val16);
    this.comment = "Value = " + this.hex2(val8);
  }
}