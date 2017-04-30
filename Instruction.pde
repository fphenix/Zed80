// Used by Class Opcodes

public class Instruction extends InstrLD8 {
  Instruction (Registers r, RAM memref, Firmware romref) {
    this.opcode = "";
    this.reg = r;
    this.ram = memref;
    this.rom = romref;
    this.NOP();
  }

  // -----------------------------------------------------------------------------------------------------
  void NOTIMP (int nbopcodebytes) {
    this.asmInstr = "NOTIMP";
    this.setPMTRpCycles(nbopcodebytes, 1, 4, 1, 0);
    this.comment = "Not-Implemented (yet!)";
  }

  /*-- class extended thru the Instr*** classes --*/
}