/*###############################################################
 #
 #  Stack (16-Bit Load Group)
 #
 + PUSH qq
 # PUSH IX
 # PUSH IY
 + POP qq
 # POP IX
 # POP IY
 #
 ###############################################################*/
// put a 16b word in the Stack (16b addr)
//void putInStack (int vall, int valh) {
// void put16InStack (int val) {
// get a 16b word from the Stack (16b addr)
//  int[] getFromStack () {
//   int get16FromStack () {


class InstrStack extends InstrJmp {

  // -----------------------------------------------------------------------------------------------------
  void PUSHqq (int qq) {
    String rQName = this.regNameQ(qq);
    this.asmInstr = "PUSH " + rQName;
    this.setPMTRpCycles(1, 3, 11, 1, 0);
    int val16 = this.getReg16Val(qq);
    this.put16InStack(val16);
    this.comment = "PUSH the value in " + rQName + " (" + this.hex4(val16) + ") on the Stack";
  }

  // -----------------------------------------------------------------------------------------------------
  void POPqq (int qq) {
    int rbn;
    if (qq == 3) {
      rbn = this.reg.Apos;
    } else {
      rbn = 2 * qq;
    }
    String rQName = this.regNameQ(qq);
    this.asmInstr = "POP " + rQName;
    this.setPMTRpCycles(1, 3, 10, 1, 0);
    int[] val = this.getFromStack();
    int val16 = (val[1] << 8) + val[0];
    this.setRegVal(rbn + 0, val[this.reg.MSB]); // MSB
    this.setRegVal(rbn + 1, val[this.reg.LSB]); // LSB
    this.comment = "POP the value in the Stack (" + this.hex4(val16) + ") in the register " + rQName;
  }

  // -----------------------------------------------------------------------------------------------------
  void PUSHIXY (int ixy) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];
    this.asmInstr = "PUSH " + ixyName;
    this.setPMTRpCycles(2, 4, 15, 2, 0);
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    this.put16InStack(val16);
    this.comment = "PUSH the value in " + ixyName + " (" + this.hex4(val16) + ") on the Stack";
  }

  // -----------------------------------------------------------------------------------------------------
  void POPIXY (int ixy) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];
    this.asmInstr = "POP " + ixyName;
    this.setPMTRpCycles(2, 4, 14, 2, 0);
    int val16 = this.get16FromStack();
    this.setReg16Val(this.reg.IXpos + ixy, val16);
    this.comment = "POP the value in the Stack (" + this.hex4(val16) + ") in the register " + ixyName;
  }


}