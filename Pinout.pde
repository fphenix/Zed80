// Used by class Z80

class Pinout {
  int ADDR; // Address bus 16-bits
  int DATA; // Data 8-bits
  int BUSACK_b; // Bus acknowledge active low
  int BUSREQ_b; // Bus Request active low
  int clock; // Clock
  int HALT_b; // Halt State
  int INT_b;  // Interrupt Request
  int M1_b;  // Machine Cycle One
  int MREQ_b; // Memory Request
  int NMI_b; // Non-Maskable Interrupt
  int RD_b; // Read
  int RESET_b; // Reset
  int RFSH_b; // Refresh
  int WAIT_b; // Wait
  int WR_b; // Write
  boolean POWER5V = true;
  boolean GROUND = false;

  boolean selGA = false;
  boolean selRAM = false;
  boolean selCRTC = false;
  boolean selROM = false;
  boolean selPRNT = false;
  boolean selPPI = false;
  boolean selXPP = false;

  // References
  Memory mem;
  GateArray ga;
  PSG psg;

  //---------------------------------------------------------------------------------
  Pinout () {
    this.ADDR = 0xFFFF;
    this.DATA = 0xFF;
    this.periphSelected(0xFFFF); // init the selXXX lines
  }

  //---------------------------------------------------------------------------------
  void setRef(Memory memref, GateArray garef, PSG psgref) {
    this.mem = memref;
    this.ga = garef;
    this.psg = psgref;
  }

  // ********************************************************************************************************
  // **             GATE ARRAY, CRTC, ROM select and PAL Memory Mapping (RAM)
  // ********************************************************************************************************

  // Hard access registers (accessed thru a 
  // LD BC, 0x7Fnn; OUT (C), C    or thru a
  // LD BC 0x7Fxx; LD <reg>, nn; OUT (C), <reg> 
  // with nn as follows:
  // * bits [7:6] : command
  // * bit   [5]  : No effect on real Gate array, i.e. Normal CPC
  // * bits [4:0] : command parameter
  // commands+b5 (b[7:5]):
  // b'000 : PENR : select a color reg; if bit 4 = 1 then border, else pen n° on [3:0]
  // b'001 : PENR-ghost
  // b'010 : INKR : value for the selected color reg: [4:0] number of the color HARD color (see colorHardware2Firmware())
  // b'011 : INKR-ghost
  // b'100 : RMR: Control Interrupt Counter, ROM mapping, Video Mode:
  //         b4 : I: '1' will reset the interrupt counter
  //         b3 : UR: Enable (0), Disable (1) the upper ROM paging (bank 3), 
  //              can select which upper ROM with the IO address 0xDF00: 
  //                ld bc, 0xDF00, OUT (c), c for Upper-ROM 0 (BASIC), 
  //                0xDF07 for  Upper-ROM7 (AMDOS)
  //         b2 : LR: Enable (0), Disable (1) the lower ROM paging
  //         b[1:0] : VM : Select the video Mode (0, 1, 2 or 3)
  // b'101 : RMR-Ghost
  // b'110 : CPC pLus only (NOT SUPPORTED)
  // The next conf is not a GA reg, but is at the same address than an unused GA reg...
  // b'11? : RAM Config : (param on bits [5:0]) : MMR : Memory Mapping (extended RAM expansion/ RAM config)
  // Note on RMR[3:2] : When ROM is Enabled: All CPU read, read the ROM, All CPU write, write the RAM at the same address
  // Ex : lb bc, 0x7F8D; OUT (c), c; => 1000_1101 => RMR, Upper and Lower ROMs disabled, VM=1

  int currpen = 0;
  int currink = 0;

  void accessGA () {
    if (this.RD_b == 0) { // W-only
      return;
    }
    int cmd = (this.DATA & 0xC0) >> 6;
    switch (cmd) {
    case 0: //PENR
      this.currpen = (this.DATA & 0x1F);
      break;
    case 1: // INKR
      this.currink = (this.DATA & 0x1F);
      if (this.currpen < 0x10) {
        this.ga.setPENHard(this.currpen, this.currink);
      } else {
        this.ga.setBORDERHard(this.currink);
      }
      break;
    case 2: // RMR
      if ((this.DATA & 0x10) == 0x10) { // RMR bit4
        println("GA RMR I register not yet uspported");
      }
      if ((this.DATA & 0x08) == 0x00) { // RMR bit 3 = UpperROM paging enable (active low)
        this.mem.upperROMpaging = true;
      } else {
        this.mem.upperROMpaging = false;
      }
      if ((this.DATA & 0x04) == 0x00) { // RMR bit 2 = LowerROM paging enable (active low)
        this.mem.lowerROMpaging = true;
      } else {
        this.mem.lowerROMpaging = false;
      }
      this.ga.setMode(this.DATA & 0x03); // RMR bits [1:0] = Video Mode
      break;
    default: // RAM/MMR 6128 Only (or extended RAM expansion)
      int page = (this.DATA & 0x38) >> 3;
      int s = (this.DATA & 0x04) >> 2;
      int bank = (this.DATA & 0x03) >> 0;
      this.mem.selExtRAMConfig(page, s, bank);
    }
  }

  int currCRTCreg = 0;
  int[] CRTCreg = {63, 40, 46, 142, 38, 0, 25, 30, 0, 7, 0, 0, 32, 0, 0, 0, 0, 0};
  int CRTCStatusreg = 0;

  void accessCRTCSel() {
    int sel = (this.ADDR & 0x0300) >> 8;
    switch (sel) {
    case 0: // 0xBCxx : W-only Select Reg
      if (this.WR_b == 0) { // Write
        this.currCRTCreg = this.DATA;
        this.currCRTCreg = (this.currCRTCreg < 0) ? 0 : (this.currCRTCreg > 31) ? 31 : this.currCRTCreg; // clamp to 0...31
      }
      break;
    case 1: // 0xBDxx : W-only Data Reg
      if (this.WR_b == 0) { // Write
        if (this.currCRTCreg <= 15) {
          this.CRTCreg[this.currCRTCreg] = this.DATA;
        }
      }
      break;
    case 2: // 0xBExx : Depends on the CRTC version; R-only ; nothing on Type 0 and 2; Status on Type 1
      if (this.RD_b == 0) { // Read
        this.DATA = this.CRTCStatusreg;
      }
      break;
    default : // 0xBFxx : Depends on the CRTC version; R-only, read reg
      if (this.RD_b == 0) { // Read
        if (this.currCRTCreg <= 17) {
          this.DATA = this.CRTCreg[this.currCRTCreg];
        } else {
          this.DATA = 0x00;
        }
      }
    }
  }

  // ********************************************************************************************************
  // **             ROM
  // ********************************************************************************************************

  void accessROMSel() {
    if (this.WR_b == 0) { // Write
      this.mem.upperROMsel = this.DATA;
    }
  }

  // ********************************************************************************************************
  // **             PPI/KEYBOARD/PSG
  // ********************************************************************************************************

  int portADirRead = 0;
  int currPortAdata = 0x00;
  int currPortBdata = 0x1E;
  int currPortCdata = 0x00;

  void accessPPISel () {
    int sel = (this.ADDR & 0x0300) >> 8 ;
    switch (sel) {
    case 0: // 0xF4, Port A Data (PSG, Keyboard/Joystick), RW
      if (this.WR_b == 0) { // Write
        this.currPortAdata = this.DATA;
      } else {
        this.DATA = this.currPortAdata;
      }
      break;
    case 1: // 0xF5, VSYNC, etc, RW
      // b7: CAS_IN
      // b6: PRN.BUSY
      // b5: /EXP
      // b4:1: 50Hz, Amstrad => b1111 (ReadOnly)
      // b0: CRTC VCYNC
      if (this.WR_b == 0) { // Write
        this.currPortBdata = this.DATA | 0x1E;
      } else {
        this.DATA = this.currPortBdata | 0x1E;
      }
      break;
    case 2: // 0xF6, PSG, Cassette, Keyboard, RW
      if (this.RD_b == 0) { // Read
        this.DATA = this.currPortCdata;
      } else { // Write
        this.accessPSG();
      }
      break;
    default:  // 0xF7, PPI Control W-Only
      if (this.RD_b == 0) { // Read?
        return;
      }
      if ((this.DATA & 0x80) == 0x80) {
        //Bit 0    IO-Cl    Direction for Port C, lower bits (always 0=Output in CPC)
        //Bit 1    IO-B     Direction for Port B             (always 1=Input in CPC)
        //Bit 2    MS0      Mode for Port B and Port Cl      (always zero in CPC)
        //Bit 3    IO-Ch    Direction for Port C, upper bits (always 0=Output in CPC)
        //Bit 4    IO-A     Direction for Port A             (0=Output, 1=Input)
        //Bit 5,6  MS0,MS1  Mode for Port A and Port Ch      (always zero in CPC)
        // CPC : Only b4 is of interest
        // Writing to PIO Control Register (with Bit7 set), automatically resets
        // PIO Ports A,B,C to 00h each!
        //In order to write to the PSG sound registers, a value of 82h must be written
        // to this register. In order to read from the keyboard (through PSG register 0Eh),
        // a value of 92h must be written to this register.
        if (this.WR_b == 0) { // Write
          this.portADirRead = ((this.DATA & 0x10) >> 4); // 1: In (read), 0:Out (write)
          this.currPortAdata = 0x00;
          this.currPortBdata = 0x1E;
          this.currPortCdata = 0x00;
        }
      } else { // b7 = 1
        // Bit 0    B        New value for the specified bit (0=Clear, 1=Set)
        // Bit 1-3  N0,N1,N2 Specifies the number of a bit (0-7) in Port C
        // Bit 4-6  -        Not Used
        int bitnb = (this.DATA & 0x0E) << 1;
        this.currPortCdata &= ~(1 << bitnb); // clear bit
        this.currPortCdata |=  ((this.DATA & 0x01) << bitnb); // write bit
      }
    }
  }



  int currPSGopWrite; // 1=W, 0=R
  int currPSGopReg; // 
  int currPSGopVal; // 
  boolean currPSGopReady = false;
  //int tapeWrite;
  //int tapeMotorOn;
  int keyboardLine = 0;



  void accessPSG() {
    // 0xF6xx Write :
    // b7:6 : PSG BDIR/BC1
    //   00 : Inactive/Validate previous operation
    //   01 : Read selected RSG Reg (value on 0xF4xx)
    //   10 : Write selected RSG Reg (value on 0xF4xx)
    //   11 : Select PSG Reg (value on 0xF4xx)
    // b5 : Cassette Write data
    // b4 : Cassette Motor Control
    // b3:0 : Select keyboard line to be scanned
    int sel = (this.DATA & 0xC0) >> 6;
    switch (sel) {
    case 0 :
      if (this.currPSGopReady) {
        if (this.currPSGopWrite == 1) {
          this.psg.writePSGreg(currPSGopReg, this.currPSGopVal);
        } else {
          this.DATA = this.psg.readPSGreg(currPSGopReg);
        }
        this.currPSGopReady = false;
      }
      break;
    case 1 :
      this.currPSGopWrite = 0;
      if (this.portADirRead == 1) {
        this.currPSGopVal = this.psg.readPSGreg(currPSGopReg);
        this.DATA = this.currPSGopVal;
        this.currPSGopReady = true;
      }
      break;
    case 2 :
      this.currPSGopWrite = 1;
      if (this.portADirRead == 0) {
        this.currPSGopVal = this.currPortAdata;
        this.psg.writePSGreg(currPSGopReg, this.currPSGopVal);
        this.currPSGopReady = true;
      }
      break;
    default:
      this.currPSGopReg = this.currPortAdata;
      this.currPSGopReady = false;
    }
    this.keyboardLine = (this.DATA & 0x0F);
  }
  /*  //write
   0xF7xx 0x82 // PortA Out
   0xF4xx regsel
   0xF6xx 0xC0 // Reg Sel
   0xF6xx 0x00 // validate
   0xF4xx write data
   0xF6xx 0x80 // data ==> regsel
   0xF6xx 0x00 // validate
   
   //read
   0xF4xx regsel
   0xF6xx 0xC0 // Reg Sel
   0xF6xx 0x00 // validate
   0xF7xx 0x92 // PortA In
   0xF6xx 0x40 // data <== regsel
   0xF4xx read data ( IN A, (C) )
   0xF7xx 0x82 // PortA Out
   0xF6xx 0x00 // validate
   */
  /* On peut aussi utiliser le vecteur 0xBD34:
   ld a,registre
   ld c,valeur
   call &bd34
   */

  // ********************************************************************************************************
  // **             MAIN
  // ********************************************************************************************************

  /* ---------------------------------------------------------------------------
   #official list, though in fact several peripherals can be accessed at the
   # same time (except the Gate array and the CRTC).
   #The selected peripheral is indicated by the 0. To select specifically one 
   # and only one peripheral, 'x' should be set to 1.
   #
   #Addr-high Addr-low Official  r/w   Name
   #   B       r/C      sel
   01xxxxxx xxxxxxxx 0x7F          w   {Gate Array}
   01xxxxxx 11xxxxxx 0x7F          w   {RAM Configuration}
   x0xxxx00 xxxxxxxx {0xBC 0xBF}   w   {CRTC6845, Cathode-Ray Tube Controller, Register select}
   x0xxxx01 xxxxxxxx {0xBC 0xBF}   w   {CRTC6845, Cathode-Ray Tube Controller, Register Data Write}
   x0xxxx10 xxxxxxxx {0xBC 0xBF}   rw  {CRTC6845, Cathode-Ray Tube Controller, Function depends on 6845 version}
   x0xxxx11 xxxxxxxx {0xBC 0xBF}   rw  {CRTC6845, Cathode-Ray Tube Controller, Function depends on 6845 version}
   xx0xxxxx xxxxxxxx 0xDF          w   {ROM select}
   xxx0xxxx xxxxxxxx 0xEF          w   {Printer port}
   xxxx0x00 dddddddd 0xF4          rw  {PPI8255 Programmable Peripheral Interface, Port A : PSG Data}
   xxxx0x01 xxxxxxxx 0xF5          rw  {PPI8255 Programmable Peripheral Interface, Port B}
   xxxx0x10 00xxxxxx 0xF6          rw  {PPI8255 Programmable Peripheral Interface, Port C : PSG Inactive ; Must be used between functions on CPC+}
   xxxx0x10 01xxxxxx 0xF6          rw  {PPI8255 Programmable Peripheral Interface, Port C : PSG Read from selected register ; data read will be available on PPI PortA which must be operating as input}
   xxxx0x10 10xxxxxx 0xF6          rw  {PPI8255 Programmable Peripheral Interface, Port C : PSG Write to selected register ; data to write is available on PPI PortA which must be operating as output}
   xxxx0x10 11xxxxxx 0xF6          rw  {PPI8255 Programmable Peripheral Interface, Port C : PSG Select a register ; register number available on PPI PortA which must be operating as output}
   xxxx0x11 xxxxxxxx 0xF7          w   {PPI8255 Programmable Peripheral Interface, Control Register}
   xxxxx0x0 0xxxxxx0 {0xF8 0xFB}   w   {Expansion Peripherals: FDC765 Floppy Disc Controller: Drive motor control}
   xxxxx0x0 0xxxxxx0 {0xF8 0xFB}   r   {Expansion Peripherals: FDC765 Floppy Disc Controller: Not used}
   xxxxx0x0 0xxxxxx1 {0xF8 0xFB}   w   {Expansion Peripherals: FDC765 Floppy Disc Controller: Drive motor control}
   xxxxx0x0 0xxxxxx1 {0xF8 0xFB}   r   {Expansion Peripherals: FDC765 Floppy Disc Controller: Not used}
   xxxxx0x1 0xxxxxx0 {0xF8 0xFB}   w   {Expansion Peripherals: FDC765 Floppy Disc Controller: Data Register}
   xxxxx0x1 0xxxxxx0 {0xF8 0xFB}   r   {Expansion Peripherals: FDC765 Floppy Disc Controller: Main Status Register}
   xxxxx0x1 0xxxxxx1 {0xF8 0xFB}   w   {Expansion Peripherals: FDC765 Floppy Disc Controller: Data Register}
   xxxxx0x1 0xxxxxx1 {0xF8 0xFB}   r   {Expansion Peripherals: FDC765 Floppy Disc Controller: Data Register}
   xxxxx0xx x0xxxxxx {0xF8 0xFB}   rw  {Expansion Peripherals: Reserved}
   xxxxx0xx 111xxxxx {0xF8 0xFB}   rw  {Expansion Peripherals: User}
   xxxxx0xx 11111111 {0xF8 0xFB}   rw  {Expansion Peripherals: Reset}
   xxxxx0xx xx0xxxxx {0xF8 0xFB}   rw  {Expansion Peripherals: Serial Port}
   --------------------------------------------------------------------------- */
  String IOselInfo (int adr) {
    String str = "";
    if ((adr & 0x8000) == 0x0000) {
      str += " | Gate Array; W-only; 0x7Fxx";
    }
    if ((adr & 0x80C0) == 0x00C0) {
      str +=  " | RAM Configuration; W-only; 0x7Fxx";
    } 
    if ((adr & 0x4300) == 0x0000) {
      str +=  " | CRTC6845, Cathode-Ray Tube Controller, Register select, 0xBCxx; W";
    } else if ((adr & 0x4300) == 0x0100) {
      str +=  " | CRTC6845, Cathode-Ray Tube Controller, Register Data Write, 0xBDxx; W";
    } else if ((adr & 0x4300) == 0x0200) {
      str +=  " | CRTC6845, Cathode-Ray Tube Controller, Function depends on 6845 version, 0xBExx; RW";
    } else if ((adr & 0x4300) == 0x0300) {
      str +=  " | CRTC6845, Cathode-Ray Tube Controller, Function depends on 6845 version, 0xBFxx; RW";
    }    
    if ((adr & 0x2000) == 0x0000) {
      str +=  " | ROM select; (W-only ???); 0xDFxx";
    } 
    if ((adr & 0x1000) == 0x0000) {
      str +=  " | Printer port; W-only; 0xEFxx";
    } 
    if ((adr & 0x0B00) == 0x0000) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF4dd, Port A : PSG Data, RW";
    } else if ((adr & 0x0B00) == 0x0100) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF5xx, Port B; RW";
    } 
    if ((adr & 0x0BC0) == 0x0200) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF6rr, Port C : PSG Inactive ; Must be used between functions on CPC+; RW";
    } else if ((adr & 0x0BC0) == 0x0240) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF6rr, Port C : PSG Read from selected register ; data read will be available on PPI PortA which must be operating as input; RW";
    } else if ((adr & 0x0BC0) == 0x0280) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF6rr, Port C : PSG Write to selected register ; data to write is available on PPI PortA which must be operating as output; RW";
    } else if ((adr & 0x0BC0) == 0x02C0) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF6rr, Port C : PSG Select a register ; register number available on PPI PortA which must be operating as output; RW";
    } 
    if ((adr & 0x0B00) == 0x0300) {
      str +=  " | PPI8255 Programmable Peripheral Interface 0xF7, Control Register, permet de choisir le mode entrée/sortie des ports; W-only";
    }
    if ((adr & 0x0581) == 0x0000) {
      str +=  " | Expansion Peripherals: FDC765 Floppy Disc Controller: Drive motor control, 0xF8-FB; W (R not uwed)";
    } else if ((adr & 0x0581) == 0x0001) {
      str +=  " | Expansion Peripherals: FDC765 Floppy Disc Controller: Drive motor control, 0xF8-FB; W (R not uwed)";
    } else if ((adr & 0x0581) == 0x0100) {
      str +=  " | Expansion Peripherals: FDC765 Floppy Disc Controller: Data Register (W) or Main Status Register (R), 0xF8-FB";
    } else if ((adr & 0x0581) == 0x0101) {
      str +=  " | Expansion Peripherals: FDC765 Floppy Disc Controller: Data Register, 0xF8-FB, RW";
    }
    if ((adr & 0x0440) == 0x0000) {
      str +=  " | Expansion Peripherals: Reserved, 0xF8-FB; RW";
    } else if ((adr & 0x04FF) == 0x00FF) {
      str +=  " | Expansion Peripherals: Reset, 0xF8-FB/0xFF ; RW";
    } else if ((adr & 0x04E0) == 0x00E0) {
      str +=  " | Expansion Peripherals: User, 0xF8-FB/0xE0-FF ; RW";
    } else if ((adr & 0x0420) == 0x0000) {
      str +=  " | Expansion Peripherals: Serial Port, 0xF8-FB ; RW";
    }
    if (str.equals("")) {
      str +=  " | No info on periph";
    }
    return str;
  }

  void periphSelected (int adr) {
    this.selGA = false;
    this.selRAM = false;
    this.selCRTC = false;
    this.selROM = false;
    this.selPRNT = false;
    this.selPPI = false;
    this.selXPP = false;
    if ((adr & 0x8000) == 0x0000) {
      this.selGA = true;
    }
    if ((adr & 0x80C0) == 0x00C0) {
      this.selRAM = true;
    } 
    if ((adr & 0x4000) == 0x0000) {
      this.selCRTC = true;
    }    
    if ((adr & 0x2000) == 0x0000) {
      this.selROM = true;
    } 
    if ((adr & 0x1000) == 0x0000) {
      this.selPRNT = true;
    } 
    if ((adr & 0x0800) == 0x0000) {
      this.selPPI = true;
    }
    if ((adr & 0x0400) == 0x0000) {
      this.selXPP = true;
    }
  }

  void accessIO () {
    if ((this.selGA) || (this.selRAM)) {
      this.accessGA();
    }
    if (this.selROM) {
      this.accessROMSel();
    }
    if (this.selCRTC) {
      this.accessCRTCSel();
    }
    if (this.selPRNT) {
      // not supported
    }
    if (this.selPPI) {
      this.accessPPISel();
    }
    if (this.selXPP) {
      // not supported
    }
  }

  void pinWriteOut (int paddr, int pdata) {
    this.ADDR = paddr;
    this.DATA = pdata;
    this.periphSelected(paddr);
    this.accessIO();
  }

  int pinReadIn (int paddr) {
    this.ADDR = paddr;
    this.periphSelected(paddr);
    this.accessIO();
    return this.DATA;
  }
}