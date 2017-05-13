/*###############################################################
 #
 # Input and Output Group
 #
 ###############################################################
 #
 # NOTE: These instructions are sometimes weird to use, especially
 # when the z80 is the heart of the Amstrad CPC.
 # For instance on CPC the peripherals are in fact wired to the
 # Higher byte of the Address bus.
 # Hence when you write:
 #   OUT (C),A
 # It will in fact send the value in the Accumulator on the address
 # pointed by the register B (Higher byte of BC), even though B is
 # not explicitely given in the instruction.
 #
 # For that same reason the INI command is buggy on CPC, because
 # B would represent both the address of the peripheric and the
 # counter, which is not possible.
 #
 + IN A,(n)
 + IN r,(C)
 + IN F,(n)  or  IN (n)
 # INI
 # INIR
 # IND
 # INDR
 + OUT (n),A
 + OUT (C),r
 + OUT (C),0
 # OUTI
 # OTIR
 # OUTD
 # OTDR
 #
 ###############################################################*/

class InstrIO extends InstrWrap {

  // -----------------------------------------------------------------------------------------------------
  void INAn (int n) {
    int val8 = this.getRegVal(this.reg.Apos);
    this.asmInstr = "IN A, (" + this.hex2(n) + ")";
    int adr16 = (val8 << 8) + (n & 0xFF);
    this.pin.WR_b = 1; // Write
    this.pin.RD_b = 0; // READ active Low 
    val8 = this.pin.pinReadIn(adr16);
    this.setRegVal(this.reg.Apos, val8);
    this.setPMTRpCycles(2, 3, 11, 1, 1);
    this.comment = "Read Peripheral; Select = " + this.hex2(val8);
    this.comment += ", DATA = " + this.hex2(n);
    this.comment += "; " + this.pin.IOselInfo(adr16);
  }

  // -----------------------------------------------------------------------------------------------------
  void INrC (int r) {
    String rName = (r == 6) ? "F" : this.regNameRS(r);
    this.asmInstr = "IN " + rName + ", (C)";
    if (r == 6) {
      this.asmInstr += " (a.k.a. 'IN (C)' )";
    }
    this.pin.WR_b = 1; // Write
    this.pin.RD_b = 0; // READ active Low 
    int adr16 = this.getReg16Val(this.reg.BCpos);
    int val8 = this.pin.pinReadIn(adr16);
    int b = this.getRegVal(this.reg.Bpos);
    this.setPMTRpCycles(2, 3, 12, 1, 0);
    if (r != 6) {
      this.setRegVal(r, val8);
    }
    this.comment = "Read Peripheral. Select = " + hex2(b);
    this.comment += ", DATA = " + hex2(val8);
    this.comment += "; " + this.pin.IOselInfo(adr16);
    this.setFlagsInType (val8);
  }

  // -----------------------------------------------------------------------------------------------------
  // Probably not used on CPC unless we need to write the same data than the select value.
  void OUTnA (int n) {
    int val8 = this.getRegVal(this.reg.Apos);
    this.asmInstr = "OUT (" + this.hex2(n) + "), A";
    int adr16 = (val8 << 8) + (n & 0xFF);
    this.pin.WR_b = 0; // Write Active Low
    this.pin.RD_b = 1; // not read    
    this.pin.pinWriteOut(adr16, val8);
    this.setPMTRpCycles(2, 3, 11, 1, 1);
    this.comment = "Write to Peripheral; Select = " + this.hex2(val8);
    this.comment += ", DATA = " + this.hex2(n);
    this.comment += "; " + this.pin.IOselInfo(adr16);
  }

  // -----------------------------------------------------------------------------------------------------
  void OUTCr (int r) {
    String rName = (r == 6) ? "0" : this.regNameRS(r);
    this.asmInstr = "OUT (C), " + rName;
    int val8 = (r == 6) ? 0 : this.getRegVal(r);
    int adr16 = this.getReg16Val(this.reg.BCpos);
    this.pin.WR_b = 0; // Write Active Low
    this.pin.RD_b = 1; // not read    
    this.pin.pinWriteOut(adr16, val8);
    this.setPMTRpCycles(2, 3, 12, 1, 1);
    int b = this.getRegVal(this.reg.Bpos);
    this.comment = "Write to Peripheral, Select = " + hex2(b);
    this.comment += ", DATA = " + hex2(val8);
    this.comment += "; " + this.pin.IOselInfo(adr16);
  }

  // -----------------------------------------------------------------------------------------------------
  void INI () {
    this.asmInstr = "INI";
    this.setPMTRpCycles(2, 4, 16, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void INIR () {
    this.asmInstr = "INIR";
    this.setPMTRpCycles(2, 5, 21, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void IND () {
    this.asmInstr = "IND";
    this.setPMTRpCycles(2, 4, 16, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void INDR () {
    this.asmInstr = "INDR";
    this.setPMTRpCycles(2, 5, 21, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void OUTI () {
    this.asmInstr = "OUTI";
    this.setPMTRpCycles(2, 4, 16, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void OTIR () {
    this.asmInstr = "OTIR";
    this.setPMTRpCycles(2, 5, 21, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void OUTD () {
    this.asmInstr = "OUTD";
    this.setPMTRpCycles(2, 4, 16, 2, 0);
    this.comment = "Not supported!";
  } 

  // -----------------------------------------------------------------------------------------------------
  void OTDR () {
    this.asmInstr = "OTDR";
    this.setPMTRpCycles(2, 5, 21, 2, 0);
    this.comment = "Not supported!";
  }
}