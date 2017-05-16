// Gate Array and CRTC (Cathode Ray Tube Controller)

class GateArray {
  int mode;
  int[] pen = new int[16];
  int[] penAlt = new int[16];
  int border, borderAlt;
  int[] flash = new int[2];
  int videoAddr;
  PImage screen;
  int pixIndex;
  int cpcWidth;
  int cpcHeight;
  int frame;
  int frameModulo;

  int borderColor = color(0, 32, 0);

  float xscl, yscl;
  int lines, columns;
  int nbrow;
  int nbrowfullscreen;
  int nbcol;
  int nbcolfullscreen;
  int borderxsize, borderysize;
  float xpad, ypad;
  final float mainscl = 2.0;

  boolean intDivRMR;
  int interruptLineCount;
  int hSyncCnt = 0;
  int sigDISPTMG = 0; // '1' if in BORDER color
  int sigBLACK = 0; // '1' if HSYNC/VSYNC active to 'display' a true black/no color
  int charSize = 8;

  // CRTC registers 0 to 17
  final int regHorizTotChar = 0;
  final int regHorizDispChar = 1; // when horiz char count equals this reg then DISPTMG set to 1
  final int regHorizSyncPosChar = 2; // start of HSync sig
  final int regHorizSyncWidth = 3;
  final int regVerticTotChar = 4;
  final int regVerticAdjust = 5; // in scan line
  final int regVerticDispChar = 6; // when vertic char count equals this reg, then DISPRMG set to 1
  final int regVerticSyncPosChar = 7; // start of VSync sig
  final int regInterlaceSkew = 8;
  final int regMaxRasterAddr = 9;
  final int regBlink = 10;
  final int regCursorPos = 11;
  final int regDispStartAddrHigh = 12;
  final int regDispStartAddrLow = 13;
  final int regCursorStartAddrHigh = 14;
  final int regCursorStartAddrLow = 15;
  final int regLightPenStartAddrHigh = 16; // read only
  final int regLightPenStartAddrLow = 17; // read only
  String[] CRTCregNames = {"HTotChar", "HDispChar", "HSyncPos", "H_V_Sync_Width (VVVVHHHH)", "VTotChar", "VAdjust", "VDispChar", "VSyncPos", "Interlace and Skew", "MaxRasterAddr", "BlinkOnOff (b6) and Speed (b5)", "CursorEndRaster", "DispStartAddrHigh", "DispStartAddrLow", "CursorAddrHigh", "CursorAddrLow", "LightPenAddrHigh", "LightPenAddrLow"};
  int[] CRTCreg = {63, 40, 46, 142, 38, 0, 25, 30, 0, 7, 0, 0, 0x30, 0, 0, 0, 0, 0};

  int HSyncWidth;
  int VSyncWidth = 16; // lines ???
  int interlace;
  int maxRasterAddr;
  int blinkOnOff;
  int blinkSpeed;
  int dispAddr;
  int dispBufferSize; // 32 or 16 KB
  int cursorAddr;
  int lightpenAddr;

  Z80 z80;       // reference
  Registers reg; // reference
  RAM ram;       // reference
  Memory mem;    // reference
  Firmware fwv;  // reference

  DebugWindow dbg;

  String instr;

  /* == Constructors ========================================= */
  GateArray () {
    this.construct(true);
  }

  GateArray (boolean shwdbg) {
    this.construct(shwdbg);
  }

  void construct (boolean shwdbg) {
    this.dbg = new DebugWindow(shwdbg);
    this.dbg.setRef(this);

    this.initColor();
    this.frame = 0;
    this.frameModulo = 1;

    screen = createImage(1, 1, RGB);
    this.setMode(1);
    this.intDivRMR = false;
  }

  void setRef(Z80 ref, Memory memref, Firmware fwvref) {
    this.z80 = ref;
    this.reg = this.z80.reg;
    this.mem = memref;
    this.fwv = fwvref;
  }

  /* == End of Constructors ======================================= */

  void initColor () {
    for (int i = 0; i < this.pen.length; i++) {
      this.pen[i] = i+1;
      this.penAlt[i] = i+1;
    }
    this.border = 1;
    this.borderAlt = 1;
  }

  void init () {
    this.cpcHeight = height;
    if (this.dbg.showDebug) {
      this.cpcWidth = 1100;
      this.dbg.xdebug = 300;
    } else {
      this.cpcWidth = 790;
      this.dbg.xdebug = 0;
    }
    this.decodeReg();
    surface.setSize(this.cpcWidth, this.cpcHeight);
    screen.resize(this.nbcolfullscreen, this.nbrowfullscreen);
    screen.loadPixels();
  }

  void calcScreenSize () {
    this.yscl = 1.0 * this.mainscl;
    this.lines = this.CRTCreg[this.regVerticDispChar]; // 25 in Char
    this.nbrow = this.lines * this.charSize; // 200 = 25 * 8
    this.nbrowfullscreen = 272;

    //Mode 1:
    this.xscl = 1.0 * this.yscl;
    this.columns = this.CRTCreg[this.regHorizDispChar]; // 40 in Char
    this.nbcol = this.columns * this.charSize; // 320 = 40 * 8
    this.nbcolfullscreen = 384; 

    //Mode 0 ou 3:
    if ((this.mode == 0) || (this.mode == 3)) {
      this.xscl *= 2.0;
      this.columns /= 2; // 20 in Char
      this.nbcol /= 2; // 160 = 20char * 8pixPerChar
      this.nbcolfullscreen /= 2; // 192
      //Mode 2:
    } else if (this.mode == 2) {
      this.xscl /= 2.0;
      this.columns *= 2; // 80 in Char
      this.nbcol *= 2; // 640 = 80 * 8
      this.nbcolfullscreen *= 2; // 768
    }

    this.xpad = floor((this.cpcWidth - (this.dbg.xdebug + (this.nbcolfullscreen * this.xscl))) / 3.0); 
    this.ypad = floor((this.cpcHeight - (this.nbrowfullscreen * this.yscl)) / 2.0);
    this.borderxsize = floor((this.nbcolfullscreen - this.nbcol) / 2.0);
    this.borderysize = floor((this.CRTCreg[this.regVerticSyncPosChar] - this.lines) * this.charSize / 2); // floor((this.nbrowfullscreen - this.nbrow) / 2.0);
  }

  void decodeReg () {
    this.charSize = (this.CRTCreg[this.regMaxRasterAddr] & 0x07) + 1;

    this.HSyncWidth = this.CRTCreg[this.regHorizSyncWidth] & 0x0F;
    this.VSyncWidth = 16; // lines ???

    this.interlace = this.CRTCreg[this.regInterlaceSkew] & 0x03;
    this.maxRasterAddr = this.CRTCreg[this.regMaxRasterAddr] & 0x07;

    this.blinkOnOff = (this.CRTCreg[this.regBlink] & 0x40) >> 6;
    this.blinkSpeed = (this.CRTCreg[this.regBlink] & 0x20) >> 5;

    int regh = this.CRTCreg[this.regDispStartAddrHigh];
    int regl = this.CRTCreg[this.regDispStartAddrLow];
    int addrBase = (regh & 0x30) << (2 + 8); // 0010_000
    int addrOffset = ((regh & 0x03) << 8) + regl;
    this.dispAddr = addrBase + addrOffset;
    this.dispBufferSize = (((regh & 0x0C) >> 2) == 0x03) ? 32 : 16; // 32 or 16 KB

    regh = this.CRTCreg[this.regCursorStartAddrHigh];
    regl = this.CRTCreg[this.regCursorStartAddrLow];
    addrBase = (regh & 0x30) << (2 + 8);
    addrOffset = ((regh & 0x03) << 8) + regl;
    this.cursorAddr = addrBase + addrOffset;

    //this.lightpenAddr = same than cursor; // not supported
    this.calcScreenSize();
    this.videoAddr = this.dispAddr;
  }

  //===================================================================================

  void setFrameMod (int m) {
    this.frameModulo = m;
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

  void setPENHard (int p, int colhard) {
    //println("Pen " + p + " ink " + col1, col2);
    this.pen[p] = this.colorHardware2Color(colhard);
    this.penAlt[p] = this.colorHardware2Color(colhard);
  }

  void setBORDERHard (int colhard) {
    //println("Border ink " + col1, col2);
    this.border = this.colorHardware2Color(colhard);
    this.borderAlt = this.colorHardware2Color(colhard);
  }

  void setFlash (int t1, int t2) {
    this.flash[0] = t1;
    this.flash[1] = t2;
  }

  void showDebugWindow () {
    this.dbg.showDebug = true;
    this.init();
  }

  void hideDebugWindow () {
    this.dbg.showDebug = false;
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

  // =================================================================================

  void display () {
    //this.showFullScreen ();
    if ((this.frame % this.frameModulo) == 0) {
      this.screen.loadPixels();
      this.showScreen();
      this.screen.updatePixels();
      pushMatrix();
      translate(this.xpad, this.ypad);
      scale(this.xscl, this.yscl);
      image(this.screen, 0, 0);
      popMatrix();
      if (this.dbg.showDebug) {
        this.dbg.showDebugScreen();
      }
    }
    this.frame++;
  }

  // =================================================================================

  int calcPixIndex (int x, int y) {
    return (x + (y * this.nbcolfullscreen));
  }

  void showFullScreen () {
    //int pidx;
    //Full screen (incl. BORDER)
    //pushMatrix();
    //translate(this.xpad, this.ypad);
    //fill(this.getBorderColor());
    //stroke(255, 0, 0);
    //rect(0, 0, this.nbcolfullscreen*this.xscl, this.nbrowfullscreen*this.yscl);
    //popMatrix();
  }

  boolean isInRegularScreen (int x, int y) {
    return ((x >= this.borderxsize) && (x < (this.borderxsize+this.nbcol)) && (y >= this.borderysize) && (y < (this.borderysize+this.nbrow)));
  }

  void showScreen() {
    int pixval;
    int pIdx = 0;
    // Regular screen
    for (int y = 0; y < this.nbrowfullscreen; y++) {
      for (int x = 0; x < this.nbcolfullscreen; x++) {
        pIdx = this.calcPixIndex(x, y);
        if (this.isInRegularScreen(x, y)) {         
          pixval = this.getPixValue(x-this.borderxsize, y-this.borderysize);
          screen.pixels[pIdx] = this.getPenColor(pixval);
        } else {
          screen.pixels[pIdx] = this.getBorderColor();
        }
        this.interruptLineCount++;
        if (this.interruptLineCount == 52) {
          this.interruptLineCount = 0;
          this.z80.interruptPending = true;
        }
      }
    }
  }

  // Transform the Hardware (GateArray) color number to the
  // Firmware (Basic/Software) color number and finally to the RGB color
  int colorHardware2Color (int hw) {
    return this.colorPalette(this.colorHardware2Firmware(hw));
  }

  // n is the Firmware color number
  int colorPalette (int ink) {
    switch (ink) {
    case 0 : 
      return #050505;
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

  int colorHardware2Firmware (int hwcolor) {
    // Pour obtenir la valeur a OUTer, hwcolor + 0x40;
    switch (hwcolor) {
    case 0x14 : // n° 20  - 01_0_10100
      return 0;
    case 0x04 : // n° 4
    case 0x10 : // n° 16
      return 1;
    case 0x15 : // n° 21
      return 2;
    case 0x1C : // n° 28
      return 3;
    case 0x18 : // n° 24
      return 4;
    case 0x1D : // n° 29
      return 5;
    case 0x0C : // n° 12
      return 6;
    case 0x05 : // n° 5
    case 0x08 : // n° 8
      return 7;
    case 0x0D : // n° 13
      return 8;
    case 0x16 : // n° 22
      return 9;
    case 0x06 : // n° 6
      return 10;
    case 0x17 : // n° 23
      return 11;
    case 0x1E : // n° 30
      return 12;
    case 0x00 : // n° 0
    case 0x01 : // n° 1
      return 13;
    case 0x1F : // n° 31
      return 14;
    case 0x0E : // n° 14
      return 15;
    case 0x07 : // n° 7
      return 16;
    case 0x0F : // n° 15
      return 17;
    case 0x12 : // n° 18
      return 18;
    case 0x02 : // n° 2
    case 0x11 : // n° 17
      return 19;
    case 0x13 : // n° 19
      return 20;
    case 0x1A : // n° 26
      return 21;
    case 0x19 : // n° 25
      return 22;
    case 0x1B : // n° 27
      return 23;
    case 0x0A : // n° 10
      return 24;
    case 0x03 : // n° 3
    case 0x09 : // n° 9
      return 25;
    case 0x0B : // n° 11
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
  // 80 bytes par line (representing 160, 320 and 640 (and 160) pixels resp.) for Mode 0, 1 and 2 (and 3)
  // Note Mode 3 is not accessible via BASIC, but can be set in Hardware (using OUT on 0x7F)
  // Mode 0, 1, 2 and 3 have respectively 2, 4, 8 and 2 (+2 unused) pixels per byte
  // Mode 0, 1, 2 and 3 have respectively 4, 2, 1 and 2 bit per pixel.
  // Mode 0, 1, 2 and 3 have respectively 16, 4, 2 and 4 different colors (plus BORDER's).

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

      //Mode 3, 160x200, 4 colors, 1 byte = 2 pixels (+2 unused)
      // bits7 and 3 = pixel0 [0:1] !!warning : reversed because it's from Mode 0 table!!
      // bits6 and 2 = pixel1 [0:1] !!warning : reversed!!
      // bits5 and 1 = unused
      // bits4 and 0 = unused
    } else if (this.mode == 3) {
      newbyte = this.clearBit(newbyte, (7 - pixnb));
      newbyte = this.clearBit(newbyte, (3 - pixnb));
      newbyte += ((pixval >> 0) & 0x01) << (7 - pixnb);
      newbyte += ((pixval >> 1) & 0x01) << (3 - pixnb);
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

      //Mode 3, 160x200, 4 colors, 1 byte = 2 pixels (+2 (4 bits) unused)
      // bits7 and 3 = pixel0 [0:1] // !! warning reversed, taken from Mode 0 table !!
      // bits6 and 2 = pixel1 [0:1] // !! reversed !!
    } else if (this.mode == 3) {
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
    } else if ((this.mode == 0) || (this.mode == 3)) {
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
    } else if ((this.mode == 0) || (this.mode == 3)) {
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
    } else if ((this.mode == 1) && (this.mode == 3)) {
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
    int byteval = this.mem.peek(byteaddr);
    int pixval = this.getPixValInByte(byteval, pixnb);
    return pixval;
  }

  // write the pixel color value of pixel @ (x, y) depending on the mode
  void setPixValue (int x, int ylinenb, int pixval) {
    int bytenb = this.calcByteNb(x);
    int pixnb = this.calcPixInByte(x);
    int byteaddr = this.calcByteAddr(ylinenb, bytenb);
    int byteval = this.mem.peek(byteaddr);
    this.mem.poke(byteaddr, this.setPixValInByte(byteval, pixnb, this.clampPixVal(pixval)));
  }

  // ====================================================================
  String hex2 (int val8) {
    return "0x" + hex(val8, 2);
  }

  String hex4 (int val16) {
    return "0x" + hex(val16, 4);
  }
}