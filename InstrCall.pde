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
    if (this.fwv.isVector(val16)) {
      this.fwv.vectorTable(val16);
    }
    this.reg.setPC(val16);
    this.comment = "Goto " + this.hex4(val16) + "; Stacked " + this.hex4(nextpc);
  }

  // -----------------------------------------------------------------------------------------------------
  void CPURSTp (int p) {
    this.handleRST(p, true);
  }

  // -----------------------------------------------------------------------------------------------------
  void RSTp (int p) {
    this.handleRST(p, false);
  }

  // -----------------------------------------------------------------------------------------------------
  void handleRST (int p, boolean fromCPU) {
    int val16 = ((p & 0x07) << 3);
    this.asmInstr = (fromCPU) ? "CPU " : "";
    this.asmInstr += "RST " + p;
    int nextpc = this.reg.getPC();
    if (!fromCPU) {
      this.setPMTRpCycles(-1, 3, 11, 1, 0);
      nextpc += abs(this.Pcycles); // stack the PC of the instr AFTER the CALL, only if NOT from System
    }
    this.put16InStack(nextpc);
    this.reg.setPC(val16);
    this.comment = "ReSTart " + this.hex4(val16) + "; Stacked " + this.hex4(nextpc);
    log.logln(this.comment);
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
    this.comment = "";
    if (testresult) {
      this.setPMTRpCycles(-3, 5, 17, 1, 2);
      int nextpc = this.reg.getPC() + abs(this.Pcycles); // stack the PC of the instr AFTER the CALL
      this.put16InStack(nextpc);
      if (this.fwv.isVector(val16)) {
        this.fwv.vectorTable(val16);
      }
      this.reg.setPC(val16);
      this.comment = "Goto " + this.hex4(val16) + "; Stacked " + this.hex4(nextpc);
    } else {
      this.setPMTRpCycles(3, 3, 10, 1, 2);
    }
    this.comment += "Condition = " + testresult;
  }

  // -----------------------------------------------------------------------------------------------------
  void RET () {
    this.asmInstr = "RET";
    this.setPMTRpCycles(-1, 4, 14, 1, 0);
    int pc = this.get16FromStack();
    this.reg.setPC(pc);
    this.comment = "RETurn to " + this.hex4(pc);
  }

  // -----------------------------------------------------------------------------------------------------
  void RETI () {
    this.asmInstr = "RETI";
    this.setPMTRpCycles(-1, 4, 14, 1, 0);
    int pc = this.get16FromStack();
    this.reg.IFF1 = this.reg.IFF2;
    this.reg.setPC(pc);
    this.comment = "RETurn from Interrupt to " + this.hex4(pc);
  }

  // -----------------------------------------------------------------------------------------------------
  void RETN () {
    this.asmInstr = "RETN";
    this.setPMTRpCycles(-1, 4, 14, 1, 0);
    int pc = this.get16FromStack();
    this.reg.IFF1 = this.reg.IFF2;
    this.reg.setPC(pc);
    this.comment = "RETurn from Non-Maskable-Interrupt to " + this.hex4(pc);
  }

  // -----------------------------------------------------------------------------------------------------
  void RETccc (int cond) {
    boolean testresult = this.reg.testCondFlag(cond);
    String cName = this.reg.condName[cond];
    this.asmInstr = "RET " + cName;
    this.comment = "";
    if (testresult) {
      this.setPMTRpCycles(-1, 3, 11, 1, 0);
      int pc = this.get16FromStack();
      this.reg.setPC(pc);
      this.comment = "RETurn to " + this.hex4(pc);
    } else {
      this.setPMTRpCycles(1, 1, 5, 1, 0);
    }
    this.comment += "Condition = " + testresult;
  }
}