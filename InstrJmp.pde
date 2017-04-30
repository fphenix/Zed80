/*###############################################################
 #
 # Jump Group
 #
 + JP nn
 + JP ccc,nn
 + JR e
 + JR ss,e
 + JP (HL)
 + JP (IX)
 + JP (IY)
 # DJNZ e
 #
 ###############################################################*/

public class InstrJmp extends InstrCall {

  // -----------------------------------------------------------------------------------------------------
  void JP (int low, int high) {
    int addr = (high << 8) + low;
    this.asmInstr = "JP " + this.hex4(addr);
    this.setPMTRpCycles(-3, 3, 10, 1, 2);
    this.reg.specialReg[this.reg.PCpos] = addr;
    this.comment = "JUMP to address " + this.hex4(addr);
  }

  // -----------------------------------------------------------------------------------------------------
  void JR (int twoscomp) {
    int jmp = this.twoComp2signed(twoscomp);
    int pc = this.reg.specialReg[this.reg.PCpos];
    this.asmInstr = "JR " + this.hex2(twoscomp);
    this.setPMTRpCycles(-2, 3, 12, 1, 1);
    this.reg.specialReg[this.reg.PCpos] = pc + 2 + jmp;
    this.comment = "JUMP-Relative by " + jmp + " bytes";
  }

  // -----------------------------------------------------------------------------------------------------
  void DJNZ (int twoscomp) {
    int jmp = this.twoComp2signed(twoscomp);
    int pc = this.reg.specialReg[this.reg.PCpos];
    this.asmInstr = "DJNZ " + this.hex2(twoscomp);
    this.setRegVal(this.reg.Bpos, (this.getRegVal(this.reg.Bpos) - 1)); // B = B - 1
    if (this.reg.reg8b[this.reg.Bpos] == 0x00) { // if B == 0, continue (don't jump)
      this.setPMTRpCycles(2, 2, 8, 1, 1);
      this.comment = "Continue; DO NOT JUMP-Relative (B = 0)";
    } else { // else if B != 0; jump relative
      this.setPMTRpCycles(-2, 3, 13, 1, 1);
      this.reg.specialReg[this.reg.PCpos] = pc + 2 + jmp;
      this.comment = "JUMP-Relative-BNotZero by " + jmp + " bytes because B != 0";
    }
  }

  // -----------------------------------------------------------------------------------------------------
  // Conditions :
  // condAsm ccc Name       FlagConcerned
  //   NZ   000   Non-Zero      Z=0
  //   Z    001   Zero          Z=1
  //   NC   010   No-Carry      C=0
  //   C    011   Carry         C=1
  //   PO   100   Parity-Odd    P/V=0
  //   PE   101   Parity-Even   P/V=1
  //   P    110   Sign-Positive S=0
  //   M    111   Sign-Negative S=1
  // -----------------------------------------------------------------------------------------------------
  void JPCond (int cond, int low, int high) {
    boolean testresult = this.reg.testCondFlag(cond);
    String cName = this.reg.condName[cond];
    int addr = (high << 8) + low;
    this.asmInstr = "JP " + cName + ", " + this.hex4(addr);
    if (testresult) {
      this.setPMTRpCycles(-3, 3, 10, 1, 2);
      this.reg.specialReg[this.reg.PCpos] = addr;
    } else {
      this.setPMTRpCycles(3, 3, 10, 1, 2);
    }
    this.comment = "Conditional JUMP to address " + this.hex4(addr);
    this.comment += " if " + cName + " true : cond=" + testresult;
  }

  // -----------------------------------------------------------------------------------------------------
  void JRCond (int cond, int twoscomp) {
    boolean testresult = this.reg.testCondFlag(cond);
    String cName = this.reg.condName[cond];
    int jmp = this.twoComp2signed(twoscomp);
    int pc = this.reg.specialReg[this.reg.PCpos];
    this.asmInstr = "JR " + cName + ", " + this.hex2(twoscomp);
    if (testresult) {
      this.setPMTRpCycles(-2, 3, 12, 1, 1);
      this.reg.specialReg[this.reg.PCpos] = pc + 2 + jmp;
    } else {
      this.setPMTRpCycles(2, 2, 7, 1, 1);
    }
    this.comment = "Conditional JUMP-Relative by " + jmp + " bytes" + " if " + cName + " true : cond=" + testresult;
  }

  // -----------------------------------------------------------------------------------------------------
  void JPcontIXY (int ixy) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];
    int addr = this.getReg16Val(this.reg.IXpos + ixy);
    //int val16 = this.get16FromRegPointer(this.reg.IXpos + ixy);
    this.asmInstr = "JP (" + ixyName + ")";
    this.setPMTRpCycles(-2, 2, 8, 2, 0);
    this.reg.specialReg[this.reg.PCpos] = addr;
    this.comment = "JUMP to the address " + this.hex4(addr) + " pointed by " + ixyName;
  }

  // -----------------------------------------------------------------------------------------------------
  void JPcontHL () {
    String dName = this.reg.reg16Name[this.reg.HLpos];
    int addr = this.getReg16Val(this.reg.HLpos);
    this.asmInstr = "JP (" + dName + ")";
    this.setPMTRpCycles(-1, 1, 4, 1, 0);
    this.reg.specialReg[this.reg.PCpos] = addr;
    this.comment = "JUMP to the address " + this.hex4(addr) + " pointed by " + dName;
  }
}