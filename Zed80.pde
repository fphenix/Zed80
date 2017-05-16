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
    cpc.setPC(0x0000);
    cpc.setSP(0x0000);
    cpc.setShowingDebugMem(0x0000);
    cpc.setBKPOff(); // off
    cpc.mem.testASM("TESTRS.BIN");
    //cpc.setBKP(0x04F7); // on
    cpc.turnon();
    cpc.setSpeed(1);
    cpc.step();
    cpc.setFrameModulo(1);
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
    log.logModeON();
    cpc.setPC(0xBEA7);
    cpc.setSP(0xBFFA);
    cpc.setBKPOff(); // off
    //cpc.setBKP(0x04F7); // on
    cpc.setReg(0xB0, 0xFF, 0x00, 0x40, 0xAB, 0xFF, 0xFF, 0x80);
    cpc.turnon();
    cpc.setSpeed(200);
    cpc.setFrameModulo(500);
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