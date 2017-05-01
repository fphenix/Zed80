CPC cpc;
Log log;

void setup () {
  size(1100, 570, P2D);
  pixelDensity(1);

  log = new Log(); // Create a new file in the sketch directory
  cpc = new CPC();

  log.logModeOFF();
  cpc.setPC(0xBEA7);
  cpc.setSP(0xBFFA);
  cpc.setBKPOff(); // off
  // cpc.setBKP(-0x4034); // on
  cpc.setReg(0xB0, 0xFF, 0x00, 0x40, 0xAB, 0xFF, 0xFF, 0x80);
  //cpc.hideDebugWindow();
  // cpc.ram.testASM();
  cpc.turnon();
  cpc.setSpeed(50);
  background(0);
}

void draw () {
  cpc.go();
}

void end () {
  log.logFlush(); // Writes the remaining data to the file
  log.logClose(); // Finishes the file
}

void mouseClicked() {
  cpc.step();
}

void keyPressed() {
  cpc.step();
}

/*
CPC cpc :
 * Firmware rom:
 * * VectorTab vt
 * RAM ram:
 * * ref Firware rom
 * Z80 z80:
 * * ref RAM ram
 * * ref Firware rom
 * * Register reg
 * * Opcodes opcode
 * * * ref Registers reg
 * * * ref RAM ram
 * * * ref Firware rom
 * * * Instruction instr
 * * * * ref Registers regArray
 * * * * ref RAM ram
 * * * * ref Firware rom
 * * * Cycle cycle
 * * Pinout pin
 * D7 diskette:
 * GateArray ga:
 * * ref Z80 z80
 * * * Registers reg
 * * ref RAM ram
 * * ref Firmware rom
 * PSG psg:
 * * ref Z80 z80
 */