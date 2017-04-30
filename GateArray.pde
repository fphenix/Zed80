// Gate Array and CRTC (Cathode Ray Tube Controller)

class GateArray {
  int mode;
  int[] pen = new int[16];
  int[] penAlt = new int[16];
  int border, borderAlt;
  int[] flash = new int[2];
  int videoAddr;
  int rate;

  int borderColor = color(0, 32, 0);
  int debugLine;

  float xscl, yscl;
  int nbrow, nbrowfullscreen;
  int nbcol, nbcolfullscreen;
  float offcol, offrow;
  float xpad, ypad;
  float mainscl;
  float xdebug;
  boolean showDebug = true;
  int regxpad = 55;
  int regypad = 16;

  Z80 z80; // ref
  Registers reg; // reference
  RAM ram; // reference
  Firmware rom; // reference
  String instr;

  int[] regsN = new int[5];
  int[] regsS = new int[4];
  int[] regsP = new int[4];
  int[] flagsArr = new int[8];

  void initArrays () {
    int i = 0;
    regsN[i++] = this.reg.BCpos;
    regsN[i++] = this.reg.DEpos;
    regsN[i++] = this.reg.HLpos;
    regsN[i++] = this.reg.IRpos;
    regsN[i++] = this.reg.AFpos;
    i = 0;
    regsS[i++] = this.reg.PCpos;
    regsS[i++] = this.reg.SPpos;
    regsS[i++] = this.reg.IXpos;
    regsS[i++] = this.reg.IYpos;
    i = 0;
    regsP[i++] = this.reg.BCpos;
    regsP[i++] = this.reg.DEpos;
    regsP[i++] = this.reg.HLpos;
    regsP[i++] = this.reg.AFpos;
    i = 0;
    flagsArr[i++] = this.reg.CFpos;
    flagsArr[i++] = this.reg.NFpos;
    flagsArr[i++] = this.reg.PVFpos;
    flagsArr[i++] = this.reg.XFpos;
    flagsArr[i++] = this.reg.HFpos;
    flagsArr[i++] = this.reg.YFpos;
    flagsArr[i++] = this.reg.ZFpos;
    flagsArr[i++] = this.reg.SFpos;
  }

  /* == Constructors ========================================= */
  GateArray () {
    this.construct(true);
  }

  GateArray (boolean shwdbg) {
    this.construct(shwdbg);
  }

  void construct (boolean shwdbg) {
    this.showDebug = shwdbg;
    this.debugLine = 0;

    this.videoAddr = 0xC000;

    this.nbrow = 200; // fixed
    this.nbrowfullscreen = 272; // fixed
    this.mainscl = 2.0; // fixed

    this.mode = 1;
    this.init();
  }

  void setRef(Z80 ref, RAM memref, Firmware romref) {
    this.z80 = ref;
    this.reg = this.z80.reg;
    this.ram = memref;
    this.rom = romref;
    this.initArrays();
  }

  /* == End of Constructors ======================================= */

  void initColor () {
    for (int i = 0; i < this.pen.length; i++) {
      this.pen[i] = i+1;
      this.penAlt[i] = i+1;
    }
    this.border = 0;
    this.borderAlt = 0;
  }

  void init () {
    int w;
    int h = 570;
    this.calcColSize();
    this.yscl = this.mainscl;
    if (this.showDebug) {
      w = 1100;
      this.xdebug = 300;
    } else {
      w = 790;
      this.xdebug = 0;
    }
    surface.setSize(w, h);
    this.xpad = (w - this.mainscl*384 - this.xdebug)/3.0; 
    this.ypad = (h - this.yscl*this.nbrowfullscreen) / 2.0;
    this.offcol = this.xscl * (this.nbcolfullscreen - this.nbcol) / 2.0;
    this.offrow = this.yscl * (this.nbrowfullscreen - this.nbrow) / 2.0;
    this.initColor();
  }

  void setInstr (String si) {
    this.instr = si;
  }

  void setMode (int m) {
    //println("Mode " + m);
    this.mode = m & 0x03;
    this.init();
  }

  int getMode () {
    return this.mode;
  }

  int getPenColor (int p) {
    int ink = this.pen[p];
    return this.colorPalette(ink);
  }

  int getBorderColor() {
    int ink = this.border;
    return this.colorPalette(ink);
  }

  void setPEN (int p, int col1, int col2) {
    //println("Pen " + p + " ink " + col1, col2);
    this.pen[p] = col1;
    this.penAlt[p] = col2;
  }

  void setBORDER (int col1, int col2) {
    //println("Border ink " + col1, col2);
    this.border = col1;
    this.borderAlt = col2;
  }

  void setFlash (int t1, int t2) {
    this.flash[0] = t1;
    this.flash[1] = t2;
  }

  void showDebugWindow () {
    this.showDebug = true;
    this.init();
  }

  void hideDebugWindow () {
    this.showDebug = false;
    this.init();
  }

  void flash () {
    int tmp;
    for (int i = 0; i < this.pen.length; i++) {
      tmp = this.pen[i];
      this.pen[i] = this.penAlt[i];
      this.penAlt[i] = tmp;
    }
    tmp = this.border;
    this.border = this.borderAlt;
    this.borderAlt = tmp;
  }

  void calcColSize () {
    switch (this.mode) {
    case 0:
      this.xscl = 2.0 * this.mainscl;
      this.nbcol = 160;
      this.nbcolfullscreen = 192;
      break;
    case 1:
      this.xscl = 1.0 * this.mainscl;
      this.nbcol = 320;
      this.nbcolfullscreen = 384;
      break;
    case 3:
      this.xscl = 2.0 * this.mainscl;
      this.nbcol = 160;
      this.nbcolfullscreen = 192;
      break;
    default:
      this.xscl = 0.5 * this.mainscl;
      this.nbcol = 640;
      this.nbcolfullscreen = 768;
      break;
    }
  }

  void display () {
    showFullScreen ();
    showScreen();
    if (this.showDebug) {
      showDebugScreen();
    }
  }

  void showDebugRegs() {
    // Debug lines : 16b registers (BC, DE, HL, IR and AF)
    fill(255, 255, 0);
    this.debugLine++;
    for (int i = 0; i < this.regsN.length; i++) {
      text(this.reg.reg16Name[this.regsN[i]], (i*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    text(this.hex4(this.reg.reg16b[this.reg.BCpos]), (0*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.reg16b[this.reg.DEpos]), (1*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.reg16b[this.reg.HLpos]), (2*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.reg16b[this.reg.IRpos]), (3*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.reg16b[this.reg.AFpos]), (4*this.regxpad)+this.xpad, this.debugLine*this.regypad);
  }

  void showDebugSpeRegs() {
    // Debug lines : PC, SP and IX, IY 16b registers
    this.debugLine++;
    for (int i = 0; i < this.regsS.length; i++) {
      if (i < 2) {
        text(this.reg.speRegName[this.regsS[i]], (i*this.regxpad)+this.xpad, this.debugLine*this.regypad);
      } else {
        text(this.reg.reg16Name[this.regsS[i]], (i*this.regxpad)+this.xpad, this.debugLine*this.regypad);
      }
    }
    this.debugLine++;
    text(this.hex4(this.reg.specialReg[this.reg.PCpos]), (0*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.specialReg[this.reg.SPpos]), (1*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.reg16b[this.reg.IXpos]), (2*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.reg16b[this.reg.IYpos]), (3*this.regxpad)+this.xpad, this.debugLine*this.regypad);
  }

  void showDebugPrimeRegs() {
    // Debug lines : Prime 16b registers
    fill(127, 127, 127);
    this.debugLine++;
    for (int i = 0; i < this.regsP.length; i++) {
      text(this.reg.reg16Name[this.regsP[i]] + "'", (i*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    text(this.hex4(this.reg.regPrime[this.reg.BCpos]), (0*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.regPrime[this.reg.DEpos]), (1*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.regPrime[this.reg.HLpos]), (2*this.regxpad)+this.xpad, this.debugLine*this.regypad);
    text(this.hex4(this.reg.regPrime[this.reg.AFpos]), (3*this.regxpad)+this.xpad, this.debugLine*this.regypad);
  }

  void showDebugFlags() {
    // Debug lines : Flags
    fill(255, 255, 0);
    this.debugLine++;
    for (int i = this.flagsArr.length - 1; i >= 0; i--) {
      text(this.reg.flagsName[this.flagsArr[i]], (i*this.regxpad/2.0)+this.xpad, this.debugLine*this.regypad);
    }
    this.debugLine++;
    for (int i = this.flagsArr.length - 1; i >= 0; i--) {
      text(this.reg.getFlagBit(i), ((this.flagsArr.length-1-i)*this.regxpad/2.0)+this.xpad, this.debugLine*this.regypad);
    }
  }

  void showDebugOpcode() {
    // show current ASM opcode
    this.debugLine++;
    this.debugLine++;
    text("Opcode : " + this.instr, this.xpad, this.debugLine*this.regypad);
  }

  void showDebugStack(int stackaddr) {
    int memp;
    int nblines = 4;
    // Debug lines : Flags
    fill(255, 255, 0);
    this.debugLine++;
    this.debugLine++;
    text("Stack : ", this.xpad, this.debugLine*this.regypad);
    this.debugLine++;
    memp = stackaddr; //this.reg.specialReg[this.reg.SPpos];
    for (int j = 0; j < nblines; j ++) {
      text(this.hex4(memp), this.xpad, (this.debugLine+j)*this.regypad);
      for (int i = 0; i < 8; i++) {
        text(hex(this.ram.peek(memp), 2), ((i+3)*this.regxpad/2.2)+this.xpad, (this.debugLine+j)*this.regypad);
        memp--;
      }
    }
    this.debugLine += nblines;
  }

  void showDebugMem(int startmem) {
    this.showDebugMem(startmem, 8, "Memory");
  }

  void showDebugMem(int startmem, int len, String title) {
    int memp;
    int nblines = len;
    // Debug lines : Flags
    fill(255, 255, 0);
    this.debugLine++;
    text(title + " : ", this.xpad, this.debugLine*this.regypad);
    this.debugLine++;
    memp = startmem;
    for (int j = 0; j < nblines; j ++) {
      text(this.hex4(memp), this.xpad, (this.debugLine+j)*this.regypad);
      for (int i = 0; i < 8; i++) {
        text(hex(this.ram.peek(memp), 2), ((i+3)*this.regxpad/2.2)+this.xpad, (this.debugLine+j)*this.regypad);
        memp++;
      }
    }
    this.debugLine += nblines;
  }

  void showDebugPCMem() {
    int startmem = this.reg.specialReg[this.reg.PCpos] - 8;
    text("=>", (this.regxpad)+this.xpad, (this.debugLine+3)*this.regypad);
    this.showDebugMem(startmem, 4, "Mem @ PC");
  }  

  void showDebugScreen () {
    //debug box
    pushMatrix();
    translate(((2.0*this.xpad)+(this.nbcolfullscreen*this.xscl)), this.ypad);
    stroke(255, 255, 0);
    fill(0, 0, 127);
    rect(0, 0, this.xdebug, this.nbrowfullscreen*this.yscl);

    this.debugLine = 0;
    this.showDebugRegs();
    this.showDebugSpeRegs();
    this.showDebugPrimeRegs();
    this.showDebugFlags();
    this.showDebugOpcode();
    this.showDebugStack(this.reg.getSP()-1);
    this.showDebugMem(this.videoAddr);
    this.showDebugPCMem();

    popMatrix();
  }

  void showFullScreen () {
    //Full screen (incl. BORDER)
    pushMatrix();
    translate(this.xpad, this.ypad);
    fill(this.getBorderColor());
    stroke(255, 0, 0);
    rect(0, 0, this.nbcolfullscreen*this.xscl, this.nbrowfullscreen*this.yscl);
    popMatrix();
  }

  void showScreen() {
    int pixval;
    // Regular screen
    pushMatrix();
    translate(this.xpad+this.offcol, this.ypad+this.offrow);
    //stroke(255);
    noStroke();
    rect(0, 0, this.nbcol*this.xscl, this.nbrow*this.yscl);

    // pixels
    noStroke();
    for (int row = 0; row < this.nbrow; row++) {
      for (int col = 0; col < this.nbcol; col++) {
        pixval = this.getPixValue(col, row);
        fill(this.getPenColor(pixval));
        rect(col*this.xscl, row*this.yscl, this.xscl, this.yscl);
      }
    }
    popMatrix();
  }

  // n is the Firmware color number
  int colorPalette (int ink) {
    switch (ink) {
    case 0 : 
      return #000000;
    case 1 : 
      return #000080;
    case 2 : 
      return #0000FF;
    case 3 : 
      return #800000;
    case 4 : 
      return #800080;
    case 5 : 
      return #8000FF;
    case 6 : 
      return #FF0000;
    case 7 : 
      return #FF0080;
    case 8 : 
      return #FF00FF;
    case 9 : 
      return #008000;
    case 10 : 
      return #008080;
    case 11 : 
      return #0080FF;
    case 12 : 
      return #808000;
    case 13 : 
      return #808080;
    case 14 : 
      return #8080FF;
    case 15 : 
      return #FF8000;
    case 16 : 
      return #FF8080;
    case 17 : 
      return #FF80FF;
    case 18 : 
      return #00FF00;
    case 19 : 
      return #00FF80;
    case 20 : 
      return #00FFFF;
    case 21 : 
      return #80FF00;
    case 22 : 
      return #80FF80;
    case 23 : 
      return #80FFFF;
    case 24 : 
      return #FFFF00;
    case 25 : 
      return #FFFF80;
    case 26 : 
      return #FFFFFF;
    default : 
      return #000000;
    }
  }

  int colorHardware2Firmware (int hw) {
    switch (hw) {
    case 0x54 : 
      return 0;
    case 0x50 : 
    case 0x44 : 
      return 1;
    case 0x55 : 
      return 2;
    case 0x5C : 
      return 3;
    case 0x58 : 
      return 4;
    case 0x5D : 
      return 5;
    case 0x4C : 
      return 6;
    case 0x45 : 
    case 0x48 : 
      return 7;
    case 0x4D : 
      return 8;
    case 0x56 : 
      return 9;
    case 0x46 : 
      return 10;
    case 0x57 : 
      return 11;
    case 0x5E : 
      return 12;
    case 0x40 : 
    case 0x41 : 
      return 13;
    case 0x5F : 
      return 14;
    case 0x4E : 
      return 15;
    case 0x47 : 
      return 16;
    case 0x4F : 
      return 17;
    case 0x52 : 
      return 18;
    case 0x42 : 
    case 0x51 : 
      return 19;
    case 0x53 : 
      return 20;
    case 0x5A : 
      return 21;
    case 0x59 : 
      return 22;
    case 0x5B : 
      return 23;
    case 0x4A : 
      return 24;
    case 0x43 : 
    case 0x49 : 
      return 25;
    case 0x4B : 
      return 26;
    default : 
      return 0;
    }
  }

  // *********************************************************************************
  // Data for the Screen starts at 0xC000 in RAM and is interlaced.
  // In normal/classic modes (against Fullscreen/demo modes), part of the memory range
  // is not displayed on the screen and can be used for data/routine storage as long
  // as the screen is not cleared.
  // There are 200 lines;
  // 80 bytes par line (representing 160, 320 and 640 pixels resp. for Mode 0, 1 and 2
  // Mode 0, 1 and 2 have respectively 2, 4 and 8 pixels per byte
  // Mode 0, 1 and 2 have respectively 4, 2 and 1 bit per pixel.
  // Mode 0, 1 and 2 have respectively 16, 4, and 2 different colors (plus BORDER's).

  // calculate a line start address (linenb should be in [0;199])
  int calcLineStartAddr (int linenb) {
    float t = (floor(linenb / 8.0) * 80) + ((linenb % 8) * 2048);
    return this.videoAddr + floor(t);
  }

  // calculate a byte address from its line number (linenb should be in [0;199])
  // and its byte number in the line (bytenb should be in [0;79])
  // WARNING : there can be SEVERAL pixels with the same address
  int calcByteAddr (int linenb, int bytenb) {
    return this.calcLineStartAddr(linenb) + bytenb;
  }

  // clear/reset a bit in a byte
  int clearBit(int byteval, int bitnb) {
    int newbyteval = byteval;
    int mask = ~(1 << bitnb);
    return newbyteval & mask;
  }

  // set a bit in a byte
  int setBit(int byteval, int bitnb) {
    int newbyteval = byteval;
    int mask = (1 << bitnb);
    return newbyteval | mask;
  }

  // return new byte value with pixel pixnb updated with value pixval
  int setPixValInByte (int prevbyteval, int pixnb, int pixval) {
    int newbyte = prevbyteval;
    //Mode 2, 640x200, 2 colors, 1 byte = 8 pixels
    // bit 7 to 0 => pixel 0 to 7
    if (this.mode == 2) {
      if (pixval == 0) {
        newbyte = this.clearBit(newbyte, (7 - pixnb));
      } else {
        newbyte = this.setBit(newbyte, (7 - pixnb));
      }
      //Mode 1, 320x200, 4 colors, 1 byte = 4 pixels
      // bits7 and 3 = pixel0 [1:0]
      // bits6 and 2 = pixel1 [1:0]
      // bits5 and 1 = pixel2 [1:0]
      // bits4 and 0 = pixel3 [1:0]
    } else if (this.mode == 1) {
      newbyte = this.clearBit(newbyte, (7 - pixnb));
      newbyte = this.clearBit(newbyte, (3 - pixnb));
      newbyte += ((pixval >> 1) & 0x01) << (7 - pixnb);
      newbyte += ((pixval >> 0) & 0x01) << (3 - pixnb);

      //Mode 0, 160x200, 16 colors, 1 byte = 2 pixels
      // bits7, 5, 3, 1 = pixel0 [bits 0,2,1,3] (!!)
      // bits6, 4, 2, 0 = pixel1 [bits 0,2,1,3] (!!)
    } else if (this.mode == 0) {
      newbyte = this.clearBit(newbyte, (7 - pixnb));
      newbyte = this.clearBit(newbyte, (5 - pixnb));
      newbyte = this.clearBit(newbyte, (3 - pixnb));
      newbyte = this.clearBit(newbyte, (1 - pixnb));
      newbyte += ((pixval >> 3) & 0x01) << (1 - pixnb); // pixval[3] -> byte[1] for pix0 or byte [0] for pix1
      newbyte += ((pixval >> 2) & 0x01) << (5 - pixnb); // pixval[2] -> byte[5] for pix0 or byte [4] for pix1
      newbyte += ((pixval >> 1) & 0x01) << (3 - pixnb); // pixval[1] -> byte[3] for pix0 or byte [2] for pix1
      newbyte += ((pixval >> 0) & 0x01) << (7 - pixnb); // pixval[0] -> byte[7] for pix0 or byte [6] for pix1
    } else {
      newbyte = 0;
    }
    return newbyte;
  }

  // get value of pixel pixnb in the byteval value, screen Mode mode
  int getPixValInByte (int byteval, int pixnb) {
    int pv = 0;
    //Mode 2, 640x200, 2 colors, 1 byte = 8 pixels
    // bit 7 to 0 => pixel 0 to 7
    if (this.mode == 2) {
      pv = (byteval >> (7 - pixnb)) & 0x01;

      //Mode 1, 320x200, 4 colors, 1 byte = 4 pixels
      // bits7 and 3 = pixel0 [1:0]
      // bits6 and 2 = pixel1 [1:0]
      // bits5 and 1 = pixel2 [1:0]
      // bits4 and 0 = pixel3 [1:0]
    } else if (this.mode == 1) {
      pv  = ((byteval >> (7 - pixnb)) & 0x01) << 1;
      pv += ((byteval >> (3 - pixnb)) & 0x01) << 0;

      //Mode 0, 160x200, 16 colors, 1 byte = 2 pixels
      // bits7, 5, 3, 1 = pixel0 [bits 0,2,1,3] (!!)
      // bits6, 4, 2, 0 = pixel1 [bits 0,2,1,3] (!!)
    } else if (this.mode == 0) {
      pv  = ((byteval >> (1 - pixnb)) & 0x01) << 3;
      pv += ((byteval >> (5 - pixnb)) & 0x01) << 2;
      pv += ((byteval >> (3 - pixnb)) & 0x01) << 1;
      pv += ((byteval >> (7 - pixnb)) & 0x01) << 0;
    } else {
      pv = 0;
    }
    return pv;
  }

  // calculate which is the Byte number in the line (from 0 to 79 incl.) for pix at x
  int calcByteNb (int x) {
    int modulo = 0;
    if (this.mode == 2) {
      modulo = 8;
    } else if (this.mode == 1) {
      modulo = 4;
    } else if (this.mode == 0) {
      modulo = 2;
    } else {
      modulo = 1;
    }
    return floor(x / modulo);
  }

  // caculate the pix number in the byte corresponding to x location in the line
  int calcPixInByte (int x) {
    int modulo = 0;
    if (this.mode == 2) {
      modulo = 8;
    } else if (this.mode == 1) {
      modulo = 4;
    } else if (this.mode == 0) {
      modulo = 2;
    } else {
      modulo = 1;
    }
    return (x % modulo);
  }

  int clampPixVal(int pixval) {
    int clamped = pixval;
    if (this.mode == 2) {
      clamped &= 0x01;  // 1bpp
    } else if (this.mode == 1) {
      clamped &= 0x03; // 2bpp
    } else if (this.mode == 0) {
      clamped &= 0x0F; // 4 bits per pix
    } else {
      clamped = pixval;
    }    
    return clamped;
  }

  // ================================================

  // read the pixel color value of pixel @ (x, y) depending on the mode
  int getPixValue (int x, int ylinenb) {
    int bytenb = this.calcByteNb(x);
    int pixnb = this.calcPixInByte(x);
    int byteaddr = this.calcByteAddr(ylinenb, bytenb);
    int byteval = this.ram.peek(byteaddr);
    int pixval = this.getPixValInByte(byteval, pixnb);
    return pixval;
  }

  // write the pixel color value of pixel @ (x, y) depending on the mode
  void setPixValue (int x, int ylinenb, int pixval) {
    int bytenb = this.calcByteNb(x);
    int pixnb = this.calcPixInByte(x);
    int byteaddr = this.calcByteAddr(ylinenb, bytenb);
    int byteval = this.ram.peek(byteaddr);
    this.ram.poke(byteaddr, this.setPixValInByte(byteval, pixnb, this.clampPixVal(pixval)));
  }

  // ====================================================================
  String hex2 (int val8) {
    return "0x" + hex(val8, 2);
  }

  String hex4 (int val16) {
    return "0x" + hex(val16, 4);
  }
}