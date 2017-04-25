int mode;
float xscl, yscl;
int nbrow, nbrowfullscreen;
int nbcol, nbcolfullscreen;
float offcol, offrow;
float xpad, ypad;
float mainscl;
float xdebug;

String[] regsN = {"AF", "BC", "DE", "HL"};
String[] regsS = {"PC", "SP", "IX", "IY"};
String[] regsP = {"A'F'", "B'C'", "D'E'", "H'L'"};

void setup () {
  size (1100, 570); // 790, 570
  nbrow = 200;
  xdebug = 300;
  nbrowfullscreen = 272;
  mode = 1;
  mainscl = 2.0;
  yscl = mainscl;
  xpad = (1100 - mainscl*384 - xdebug)/3.0; 
  ypad = (570 - yscl*nbrowfullscreen) / 2.0;
  switch (mode) {
  case 0:
    xscl = 2.0 * mainscl;
    nbcol = 160;
    nbcolfullscreen = 192;
    break;
  case 1:
    xscl = 1.0 * mainscl;
    nbcol = 320;
    nbcolfullscreen = 384;
    break;
  case 3:
    xscl = 0;
    nbcol = 0;
    nbcolfullscreen = 0;
    break;
  default:
    xscl = 0.5 * mainscl;
    nbcol = 640;
    nbcolfullscreen = 768;
    break;
  }
  offcol = xscl * (nbcolfullscreen - nbcol) / 2.0;
  offrow = yscl * (nbrowfullscreen - nbrow) / 2.0;
  println(nbcolfullscreen*xscl, nbrowfullscreen*yscl);
  println(((2*xpad)+(nbcolfullscreen*xscl)), ypad);
  println(offcol, offrow);
}

void draw () {
  background(0);

  showFullScreen ();
  showScreen();
  showDebugScreen();
}

void showDebugScreen () {
  //debug box
  pushMatrix();
  translate(((2*xpad)+(nbcolfullscreen*xscl)), ypad);
  stroke(255, 255, 0);
  fill(0, 0, 127);
  rect(0, 0, xdebug, nbrowfullscreen*yscl);
  fill(255, 255, 0);
  for (int i = 0; i < regsN.length; i++) {
    text(regsN[i], i*40+10, 20);
  }
  popMatrix();
}

void showFullScreen () {
  //Full screen (incl. BORDER)
  pushMatrix();
  translate(xpad, ypad);
  fill(0, 64, 0);
  stroke(255, 0, 0);
  rect(0, 0, nbcolfullscreen*xscl, nbrowfullscreen*yscl);
  popMatrix();
}

void showScreen() {
  // Regular screen
  pushMatrix();
  translate(xpad+offcol, ypad+offrow);
  stroke(255);
  rect(0, 0, nbcol*xscl, nbrow*yscl);

  // pixels
  for (int row = 0; row < nbrow; row++) {
    for (int col = 0; col < nbcol; col++) {
      stroke(0, 255, 0, 100);
      fill((col*2)%255, (row*2)%255, 255, 128);
      rect(col*xscl, row*yscl, xscl, yscl);
    }
  }
  popMatrix();
}