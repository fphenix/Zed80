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
    int adr16 = (val8 << 8) + n;
    this.pin.ADDR = adr16;
    this.setRegVal(this.reg.Apos, this.pin.DATA);
    this.setPMTRpCycles(2, 3, 11, 1, 1);
    this.comment = "Read Peripheral";
    this.comment += "; " + this.pin.IOselInfo(adr16);
  }

  // -----------------------------------------------------------------------------------------------------
  void INrC (int r) {
    String rName = (r == 6) ? "F" : this.regNameRS(r);
    this.asmInstr = "IN " + rName + ", (C)";
    if (r == 6) {
      this.asmInstr += " (a.k.a. 'IN (C)' )";
    }

    int adr16 = this.getReg16Val(this.reg.BCpos);
    this.pin.ADDR = adr16;
    int val8 = this.pin.DATA;
    this.setPMTRpCycles(2, 3, 12, 1, 0);
    this.comment = "Read from Peripheral, Warning! On CPC the select is in fact B=" + hex2( this.getRegVal(this.reg.Bpos));
    this.comment += ", the value on DATA is reg " + rName;
    if (r != 6) {
      this.setRegVal(r, val8);
      this.comment += ", value=" + hex2(val8);
    }
    this.comment += "; " + this.pin.IOselInfo(adr16);

    // Flag byte:
    int sf, zf, yf, hf, xf, pvf, nf, cf;
    sf = this.rshiftMask(val8, this.reg.SFpos, 0x01);
    zf = this.isZero(val8); 
    yf = this.rshiftMask(val8, this.reg.YFpos, 0x01);
    hf = 0;
    xf = this.rshiftMask(val8, this.reg.XFpos, 0x01);
    pvf = this.parity(val8);
    nf = 0;
    cf = this.reg.getCF();
    this.reg.setFlags(sf, zf, yf, hf, xf, pvf, nf, cf);
  }

  // -----------------------------------------------------------------------------------------------------
  void OUTnA (int n) {
    int val8 = this.getRegVal(this.reg.Apos);
    this.asmInstr = "OUT (" + this.hex2(n) + "), A";
    int adr16 = (val8 << 8) + n;
    this.pin.ADDR = adr16;
    this.pin.DATA = val8;
    this.setPMTRpCycles(2, 3, 11, 1, 1);
    this.comment = "Write to Peripheral; CPC??? sel A, data A ???";
    this.comment += "; " + this.pin.IOselInfo(adr16);
  }

  // -----------------------------------------------------------------------------------------------------
  void OUTCr (int r) {
    String rName = (r == 6) ? "0" : this.regNameRS(r);
    this.asmInstr = "OUT (C), " + rName;
    int val8 = (r == 6) ? 0 : this.getRegVal(r);
    int adr16 = this.getReg16Val(this.reg.BCpos);
    if (adr16 == 0x7f8d) {
    cpc.ga.mode = 1;
    }
    this.pin.ADDR = adr16;
    this.pin.DATA = val8;
    this.setPMTRpCycles(2, 3, 12, 1, 1);
    this.comment = "Write to Peripheral, Warning! On CPC the select is in fact B=" + hex2( this.getRegVal(this.reg.Bpos));
    this.comment += ", the value on DATA is ";
    if (r != 6) {
      this.comment += "reg " + rName + ", ";
    }
    this.comment += "value=" + hex2(val8);
    this.comment += "; " + this.pin.IOselInfo(adr16);
  }

}