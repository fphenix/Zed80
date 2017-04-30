/*###############################################################
 #
 # Call and Return Group
 #
 + CALL nn
 + CALL cc,nn
 + RET
 + RET cc
 # RETI
 # RETN
 # RST p
 #
 ###############################################################*/

class InstrCall extends InstrBSRT {

  // -----------------------------------------------------------------------------------------------------
  void CALLnn (int vall, int valh) {
    int val16 = ((valh & 0xFF) << 8) + (vall & 0xFF);
    this.asmInstr = "CALL " + this.hex4(val16);
    this.setPMTRpCycles(-3, 5, 17, 1, 2);
    int nextpc = this.reg.getPC() + abs(this.Pcycles); // stack the PC of the instr AFTER the CALL
    this.put16InStack(nextpc);
    if (this.rom.isVector(val16)) {
      this.rom.vectorTable(val16);
    }
    this.reg.setPC(val16);
    this.comment = "CALL sub routine at " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void RET () {
    this.asmInstr = "RET";
    this.setPMTRpCycles(-1, 4, 14, 1, 0);
    int pc = this.get16FromStack();
    this.reg.setPC(pc);
    this.comment = "RETurn from sub routine, go back to " + this.hex4(pc);
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
  void CALLcccnn (int cond, int vall, int valh) {
    boolean testresult = this.reg.testCondFlag(cond);
    String cName = this.reg.condName[cond];
    int val16 = ((valh & 0xFF) << 8) + (vall & 0xFF);
    this.asmInstr = "CALL " + cName + ", " + this.hex4(val16);
    if (testresult) {
      this.setPMTRpCycles(-3, 5, 17, 1, 2);
      int nextpc = this.reg.getPC() + abs(this.Pcycles); // stack the PC of the instr AFTER the CALL
      this.put16InStack(nextpc);
      if (this.rom.isVector(val16)) {
        this.rom.vectorTable(val16);
      }
      this.reg.setPC(val16);
    } else {
      this.setPMTRpCycles(-3, 3, 10, 1, 2);
    }
    this.comment = "Conditional-CALL sub routine at " + this.hex4(val16);
    this.comment += " if " + cName + " is true : cond=" + testresult;
  }

  // -----------------------------------------------------------------------------------------------------
  void RETccc (int cond) {
    boolean testresult = this.reg.testCondFlag(cond);
    String cName = this.reg.condName[cond];
    this.asmInstr = "RET " + cName;
    int flags = this.reg.readFlagByte();
    this.comment = "Conditional-RETurn from sub routine, Flags=" + this.hex2(flags) + ", ";
    if (testresult) {
      this.setPMTRpCycles(-1, 3, 11, 1, 0);
      int pc = this.get16FromStack();
      this.reg.setPC(pc);
      this.comment += "go back to " + this.hex4(pc) + " if " + cName + " is true : cond=" + testresult;
    } else {
      this.setPMTRpCycles(1, 1, 5, 1, 0);
      this.comment = "FALSE: condition " + cName + " is not met";
    }
  }
}