import java.awt.event.KeyEvent;

CPC cpc;
Log log;
Log dbglog;

boolean test = false;

int starttime;
boolean loaded = false;

void setup () {
  size(1100, 570, P2D);
  pixelDensity(1);

  log = new Log(); // Create a new file in the sketch directory
  dbglog = new Log("DebugFDC.txt"); // Create a new file in the sketch directory

  if (test) {
    cpc = new CPC();
    log.logModeON(0x4000);
    dbglog.logModeON();
    cpc.setPC(0x0000);
    cpc.setSP(0x6000);
    cpc.setShowingDebugMem(0x0000);
    cpc.setBKPOff(); // off
    cpc.mem.testASM("TESTCOLORS.BIN");
    cpc.attachFloppyDisc("HEADOVER.DSK");
    //cpc.setBKP(0x04F7); // on
    cpc.turnon();
    cpc.setSpeed(2000);
    cpc.setDebugRefresh(50);
    cpc.step();
  } else {
    cpc = new CPC();
    dbglog.logModeON();
    log.logModeON(0xBEA7);
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
  if ((millis() - starttime > 10000) && !loaded) {
    //    println("Loading game!");
//    cpc.mem.testASM("TESTCOLORS.BIN");
//    cpc.setPC(0x4000);
    loaded = true;
    //    this.cpc.runD7file("HEADOVER.BIN");
    //    this.cpc.mem.ram[0].data[0x1BD6] = 0xCD;
    //    this.cpc.mem.ram[0].data[0x1BD7] = 0xA7;
    //    this.cpc.mem.ram[0].data[0x1BD8] = 0xBE;
    //    this.cpc.mem.ram[0].data[0xBC7A] = 0xC9;
    this.cpc.mem.memDump();
    println("mem dumped!");
    //    this.cpc.z80.reg.specialReg[this.cpc.z80.reg.PCpos] = 0xBEA7;
    //    this.cpc.z80.reg.specialReg[this.cpc.z80.reg.SPpos] = 0xBFFA;
  }
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