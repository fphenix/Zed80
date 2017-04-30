// Used by class Z80

class Pinout {
  int addr; // Address bus 16-bits
  int data; // Data 8-bits
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
    this.addr = 0xFFFF;
    this.data = 0xFF;
  }

  boolean gateArraySelected () {
    return ((this.addr & 0xC000) == 0x4000); // to verify
  }

  void selectGateArray (int a) {
    this.addr = (a & 0x3FFF) | 0x4000; // to verify
  }
}