CPC cpc; //<>// //<>//
Log log;

boolean boot = false;
//boolean runp = true;
boolean test = false;

void setup () {
  size(1100, 570, P2D);
  pixelDensity(1);

  log = new Log(); // Create a new file in the sketch directory

  if (test) {
    cpc = new CPC(false);
    log.logModeON();
    cpc.setPC(0x4000);
    cpc.setSP(0x0000);
    cpc.setShowingDebugMem(0x0000);
    cpc.setBKPOff(); // off
    cpc.mem.testASM("TESTINT.BIN");
    //cpc.setBKP(0x04F7); // on
    cpc.turnon();
    cpc.setSpeed(1000);
    cpc.step();
    cpc.setFrameModulo(400);
  } else if (boot) {
    cpc = new CPC();
    log.logModeON();
    cpc.setPC(0x0);
    cpc.setSP(0x0);
    cpc.setBKPOff(); // off
    //cpc.setBKP(0x04F7); // on
    //cpc.hideDebugWindow();
    cpc.turnon();
    cpc.setSpeed(500);
    cpc.setFrameModulo(500);
  } else {
    cpc = new CPC(boot);
    log.logModeON(0x048B);
    cpc.setBKPOff(); // off
    //cpc.setBKP(0x04F7); // on
    cpc.setPC(0xBEA7); // PC reg
    cpc.setSP(0xBFFA); // SP reg
    cpc.setRegs(0xFF, 0xB0, 0xFF, 0x00, 0x40, 0xAB, 0xFF, 0xA8); //A,B,C,D,E,H,L,F
    cpc.setPrimes(0x8D, 0x7F, 0x8D, 0xBE, 0xA7, 0xB1, 0xAB, 0x8C); //A,B,C,D,E,H,L,F
    cpc.setSpeRegs (0x00, 0x5A, 0x0000, 0x0000); // I, R, IX, IY
    cpc.mem.poke(0xBA1D, 0xC9);
    cpc.turnon();
    cpc.setSpeed(600);
    cpc.setFrameModulo(200);
  }
  background(0);
}

void draw () {
  //cpc.step();
  cpc.go();
}

void end () {
  log.logFlush(); // Writes the remaining data to the file
  log.logClose(); // Finishes the file
}

void mouseClicked() {
  cpc.step();
  //log.logFlush(); // Writes the remaining data to the file
}

void keyPressed() {
  cpc.z80.reg.setBKPOff();
  cpc.go();
}