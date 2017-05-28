class Touche {
  int line;
  int bitpos;
  int id;
  int keyEventJava;
  boolean majOn = false;
  boolean ctrlOn = false;

  Touche (int ln, int bp) {
    this.setTouche(ln, bp, false, false);
  }

  Touche (int ln, int bp, boolean maj) {
    this.setTouche(ln, bp, maj, false);
  }

  Touche (int ln, int bp, boolean maj, boolean ctr) {
    this.setTouche(ln, bp, maj, ctr);
  }

  void setTouche (int ln, int bp, boolean shiftOn, boolean ctrOn) {
    this.line = ln;
    this.bitpos = bp;
    this.majOn = shiftOn;
    this.ctrlOn = ctrOn;
    this.id = (this.line * 8) + this.bitpos;
  }

  void setKeyEvent (int kev) {
    this.keyEventJava = kev;
  }

  int getLine () {
    return this.line;
  }

  int getBit () {
    return this.bitpos;
  }
}