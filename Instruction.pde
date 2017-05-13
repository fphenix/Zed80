// Used by Class Opcodes

public class Instruction extends InstrLD8 {

  Instruction () {
    this.opcode = "";
    this.NOP();
  }

  void setRef(Registers regref, Pinout pinref, Memory memref, Firmware fwvref) {
    this.reg = regref;
    this.pin = pinref;
    this.mem = memref;
    this.fwv = fwvref;
  }

  // -----------------------------------------------------------------------------------------------------
  void NOTIMP (int nbopcodebytes) {
    this.asmInstr = "NOTIMP";
    this.setPMTRpCycles(nbopcodebytes, 1, 4, 1, 0);
    this.comment = "Not-Implemented (yet!)";
  }

  // -----------------------------------------------------------------------------------------------------
  void PHDD (int nbopcodebytes) {
    this.asmInstr = "DNOP";
    this.setPMTRpCycles(nbopcodebytes, 1, 4, 1, 0);
    this.comment = "Place Holder 0xDD/0xFD (NOP)";
  }

  /*-- class extended thru the Instr*** classes --*/
}