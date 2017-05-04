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

  Pinout () {
    this.ADDR = 0xFFFF;
    this.DATA = 0xFF;
  }

  boolean gateArraySelected () {
    return ((this.ADDR & 0xC000) == 0x4000); // to verify
  }

  void selectGateArray (int a) {
    this.ADDR = (a & 0x3FFF) | 0x4000; // to verify
  }

  /* ---------------------------------------------------------------------------
   #official list, though in fact several peripherals can be accessed at the
   #same time (except the Gate array and the CRTC).
   #The selected peripheral is indicated by the 0.
   #Only high byte B is given
   #
   #Addr-high Addr-low Official r/w Name
   01xxxxxx xxxxxxxx 0x7F          w   {Gate Array}
   0xxxxxxx xxxxxxxx 0x7F          w   {RAM Configuration}
   x0xxxx00 xxxxxxxx {0xBC 0xBF}   w   {CRTC6845, Cathode-Ray Tube Controller, Register select}
   x0xxxx01 xxxxxxxx {0xBC 0xBF}   w   {CRTC6845, Cathode-Ray Tube Controller, Register Write}
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
   */
  String IOselInfo (int adr) {
    String str = "";
    if ((adr & 0xC000) == 0x4000) {
      str += "Gate Array; W-only; 0x7F";
    }
    if ((adr & 0x8000) == 0x0000) {
      str +=  "RAM Configuration; W-only; 0x7F";
    } 
    if ((adr & 0x2000) == 0x0000) {
      str +=  "ROM select; (W-only ???); 0xDF";
    } 
    if ((adr & 0x1000) == 0x0000) {
      str +=  "Printer port; W-only; 0xEF";
    } 
    if ((adr & 0x0B00) == 0x0000) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF4, Port A : PSG Data, RW";
    } 
    if ((adr & 0x0B00) == 0x0100) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF5, Port B; RW";
    } 
    if ((adr & 0x0BC0) == 0x0200) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF6, Port C : PSG Inactive ; Must be used between functions on CPC+; RW";
    } 
    if ((adr & 0x0BC0) == 0x0240) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF6, Port C : PSG Read from selected register ; data read will be available on PPI PortA which must be operating as input; RW";
    } 
    if ((adr & 0x0BC0) == 0x0280) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF6, Port C : PSG Write to selected register ; data to write is available on PPI PortA which must be operating as output; RW";
    } 
    if ((adr & 0x0BC0) == 0x02C0) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF6, Port C : PSG Select a register ; register number available on PPI PortA which must be operating as output; RW";
    } 
    if ((adr & 0x0B00) == 0x0300) {
      str +=  "PPI8255 Programmable Peripheral Interface 0xF7, Control Register, permet de choisir le mode entrée/sortie des ports; W-only";
    } else {
      str +=  "; No info on periph";
    }
    return str;
  }
  /* to do :
   x0xxxx00 xxxxxxxx {0xBC 0xBF}   w   {CRTC6845, Cathode-Ray Tube Controller, Register select}
   x0xxxx01 xxxxxxxx {0xBC 0xBF}   w   {CRTC6845, Cathode-Ray Tube Controller, Register Write}
   x0xxxx10 xxxxxxxx {0xBC 0xBF}   rw  {CRTC6845, Cathode-Ray Tube Controller, Function depends on 6845 version}
   x0xxxx11 xxxxxxxx {0xBC 0xBF}   rw  {CRTC6845, Cathode-Ray Tube Controller, Function depends on 6845 version}
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
   */

}