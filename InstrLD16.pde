/*###############################################################
 #
 #  16-Bit Load Group
 #
 + LD dd,nn ; dd=BC,DE,HL,SP
 # LD IX,nn
 # LD IY,nn
 + LD HL,(nn)
 + LD dd,(nn)
 # LD IX,(nn)
 # LD IY,(nn)
 + LD (nn),HL
 + LD (nn),dd
 # LD (nn),IX
 # LD (nn),IY
 + LD SP,HL
 # LD SP,IX
 # LD SP,IY
 #
 ###############################################################*/

class InstrLD16 extends InstrAL8 {

  // -----------------------------------------------------------------------------------------------------
  void LDdval (int d, int low, int high) {
    String dName = this.regNameD(d);
    int val16 = ((high & 0xFF) << 8) + (low & 0xFF);
    this.asmInstr = "LD " + dName + ", " + this.hex4(val16);
    this.setPMTRpCycles(3, 3, 10, 1, 2);
    switch (d) {
    case 0:
      this.setRegVal(this.reg.Bpos, high);
      this.setRegVal(this.reg.Cpos, low);
      break;
    case 1:
      this.setRegVal(this.reg.Dpos, high);
      this.setRegVal(this.reg.Epos, low);
      break;
    case 2:
      this.setRegVal(this.reg.Hpos, high);
      this.setRegVal(this.reg.Lpos, low);
      break;
    default:
      this.reg.specialReg[this.reg.SPpos] = val16;
    }
    this.comment = "Load 16b reg " + dName + " with value " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDdcontval (int d, int memlow, int memhigh) {
    String dName = this.regNameD(d);
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val16 = this.get16FromPointer(mem16);
    int low = (val16 >> 0) & 0xFF;
    int high = (val16 >> 8) & 0xFF;
    this.asmInstr = "LD " + dName + ", (" + this.hex4(mem16) + ")";
    this.setPMTRpCycles(4, 6, 20, 2, 2);
    switch (d) {
    case 0:
      this.setRegVal(this.reg.Bpos, high);
      this.setRegVal(this.reg.Cpos, low);
      break;
    case 1:
      this.setRegVal(this.reg.Dpos, high);
      this.setRegVal(this.reg.Epos, low);
      break;
    case 2:
      this.setRegVal(this.reg.Hpos, high);
      this.setRegVal(this.reg.Lpos, low);
      break;
    default:
      this.reg.specialReg[this.reg.SPpos] = val16;
    }
    this.comment = "Load 16b reg " + dName + " with content of addr " + this.hex4(mem16);
    this.comment += ", value " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontvald (int d, int memlow, int memhigh) {
    String dName = this.regNameD(d);
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val16;
    this.asmInstr = "LD (" + this.hex4(mem16) + "), " + dName;
    this.setPMTRpCycles(4, 6, 20, 2, 2);
    switch (d) {
    case 3:
      val16 = this.reg.specialReg[this.reg.SPpos];
      break;
    default:
      val16 = this.getReg16Val(d);
    }
    this.put16InPointer(mem16, val16);
    this.comment = "Load content of addr " + this.hex4(mem16) + ", value ";
    this.comment += this.hex4(val16) + ", in 16b reg " + dName;
  }

  // -----------------------------------------------------------------------------------------------------
  void LDHLcontval (int memlow, int memhigh) {
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val16 = this.get16FromPointer(mem16);
    int low = (val16 >> 0) & 0xFF;
    int high = (val16 >> 8) & 0xFF;
    this.asmInstr = "LD HL, (" + this.hex4(mem16) + ")";
    this.setPMTRpCycles(3, 5, 16, 1, 2);
    this.setRegVal(this.reg.Hpos, high);
    this.setRegVal(this.reg.Lpos, low);
    this.comment = "Load HL with content of addr " + this.hex4(mem16) + ", value " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontvalHL (int memlow, int memhigh) {
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    this.asmInstr = "LD (" + this.hex4(mem16) + "), HL";
    this.setPMTRpCycles(3, 5, 16, 1, 2);
    int val16 = this.reg.reg16b[this.reg.HLpos];
    this.put16InPointer(mem16, val16);
    this.comment = "Load content of addr " + this.hex4(mem16) + ", value " + this.hex4(val16) + ", in HL";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDIXYval (int ixy, int low, int high) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int val16 = ((high & 0xFF) << 8) + (low & 0xFF);
    this.asmInstr = "LD " + ixyName + ", " + this.hex4(val16);
    this.setPMTRpCycles(4, 4, 14, 2, 2);
    this.setReg16Val(this.reg.IXpos + ixy, val16);
    this.comment = "Load " + ixyName + " with value " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDIXYcontval (int ixy, int memlow, int memhigh) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val16 = this.get16FromPointer(mem16);
    this.asmInstr = "LD " + ixyName + ", " + this.hex4(val16);
    this.setPMTRpCycles(4, 4, 14, 2, 2);
    this.setReg16Val(this.reg.IXpos + ixy, val16);
    this.comment = "Load " + ixyName + " with memory content (" + this.hex4(mem16);
    this.comment += "), value " + this.hex4(val16);
  }

  // -----------------------------------------------------------------------------------------------------
  void LDcontvalIXY (int ixy, int memlow, int memhigh) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    int mem16 = ((memhigh & 0xFF) << 8) + (memlow & 0xFF);
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    this.asmInstr = "LD (" + this.hex4(val16) + "), " + ixyName;
    this.setPMTRpCycles(4, 6, 20, 2, 2);
    this.put16InPointer(mem16, val16);
    this.comment = "Load " + ixyName + ", value " + this.hex4(val16);
    this.comment += ") at memory address (" + this.hex4(mem16) + ")";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDSPHL () {
    this.asmInstr = "LD SP, HL" ;
    this.setPMTRpCycles(1, 1, 6, 1, 0);
    int val16 = this.getReg16Val(this.reg.HLpos);
    this.reg.specialReg[this.reg.SPpos] = val16;
    this.comment = "Value in register HL (" + this.hex4(val16) + ") copied into register SP";
  }

  // -----------------------------------------------------------------------------------------------------
  void LDSPIXY (int ixy) {
    String ixyName = this.reg.reg16Name[this.reg.IXpos + ixy];    
    this.asmInstr = "LD SP, " + ixyName ;
    this.setPMTRpCycles(2, 2, 10, 2, 0);
    int val16 = this.getReg16Val(this.reg.IXpos + ixy);
    this.reg.specialReg[this.reg.SPpos] = val16;
    this.comment = "Value in register " + ixyName + " (" + this.hex4(val16) + ") copied into register SP";
  }

}