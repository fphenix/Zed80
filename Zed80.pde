import java.awt.event.KeyEvent;

CPC cpc;
Log log;
Log dbglog;
Log psglog;

boolean test = false;

int starttime;
boolean loaded = false;

void setup () {
  size(1100, 570, P2D);
  pixelDensity(1);

  log = new Log(); // Create a new file in the sketch directory
  dbglog = new Log("DebugFDC.txt"); // Create a new file in the sketch directory
  psglog = new Log("PSG.log");
  psglog.logModeON();

  if (test) {
    cpc = new CPC();
    log.logModeON(0x4000);
    dbglog.logModeON();
    cpc.setPC(0x0000);
    cpc.setSP(0x6000);
    cpc.setShowingDebugMem(0x4000);
    cpc.setBKPOff(); // off
    cpc.mem.testASM("TESTSND.BIN");
    cpc.attachFloppyDisc("HEADOVER.DSK");
    //cpc.setBKP(0x04F7); // on
    cpc.turnon();
    cpc.setSpeed(2000);
    cpc.setDebugRefresh(50);
    cpc.step();
  } else {
    cpc = new CPC();
    dbglog.logModeON();
    //log.logModeON(0x0474);
    cpc.setPC(0x0);
    cpc.setSP(0x0);
    //cpc.setPC(0xBEA7); // PC reg
    //cpc.setSP(0xBFFA); // SP reg
    cpc.setBKPOff(); // off
    //cpc.setBKP(0x04F7); // on
    //cpc.hideDebugWindow();
    //cpc.setRegs(0xFF, 0xB0, 0xFF, 0x00, 0x40, 0xAB, 0xFF, 0xA8); //A,B,C,D,E,H,L,F
    //cpc.setPrimes(0x8D, 0x7F, 0x8D, 0xBE, 0xA7, 0xB1, 0xAB, 0x8C); //A,B,C,D,E,H,L,F
    //cpc.setSpeRegs (0x00, 0x5A, 0x0000, 0x0000); // I, R, IX, IY
    cpc.attachFloppyDisc("HEADOVER.DSK");
    cpc.turnon();
    cpc.setSpeed(3000);
    cpc.setDebugRefresh(150);
  } 
  background(0);
  starttime = millis();
}

void draw () {
  //cpc.step();
  cpc.go();
  if ((millis() - starttime > 7000) && !loaded) {
    loaded = true;
    cpc.mem.testASM("TESTSND.BIN");
    cpc.mem.memDump();
    println("mem dumped!");
    //cpc.setPC(0x4000);
    //cpc.setSP(0x5000);
  }
  psglog.logFlush();
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
  this.cpc.kb.updateKBKeyPressed(keyCode);
}

void keyReleased() {
  this.cpc.kb.updateKBKeyReleased(keyCode);
}