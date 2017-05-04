// Used by class Z80

class Registers {
  public final int regLen = 11;
  public final int regPrimeLen = 9;
  public final int reg16bLen = 7;
  public final int reg16bPrimeLen = 4;
  public final int speRegLen = 2;
  public final int FlagsLen = 8;

  public final String[] regName = {"B", "C", "D", "E", "H", "L", "(HL)", "A", "F", "I", "R"};
  public final int Bpos = 0;
  public final int Cpos = 1;
  public final int Dpos = 2;
  public final int Epos = 3;
  public final int Hpos = 4;
  public final int Lpos = 5;
  public final int contHLpos = 6; // placeHolder
  public final int Apos = 7;  
  public final int Fpos = 8;
  public final int Ipos = 9;
  public final int Rpos = 10;

  public final String[] speRegName = {"PC", "SP"};
  public final int PCpos = 0; // Program Counter
  public final int SPpos = 1; // Stack Pointer

  public final String[] reg16Name = {"BC", "DE", "HL", "AF", "IR", "IX", "IY"};
  public final int BCpos = 0; // General Purpose Registers (Counter, destination, 16b, etc.)
  public final int DEpos = 1; // General Purpose Registers (Counter, destination, 16b, etc.)
  public final int HLpos = 2; // General Purpose Registers (Counter, destination, 16b, etc.)
  public final int AFpos = 3; // Accumulator and Flags
  public final int IRpos = 4; // Note: during refresh cycle IR is put on ADDR
  public final int IXpos = 5; // Index Registers
  public final int IYpos = 6; // Index Registers

  // Flags : S Z y H x PV N C
  public final String[] flagsName = {"S", "Z", "y", "H", "x", "P/V", "N", "C"};
  public final int SFpos = 7; // bit 7 of Flag Reg. ; Set ('1') if 2-complement value is negative (i.e. copy of the Most-Significant-Bit)
  public final int ZFpos = 6; // bit 6 of Flag Reg. ; Set ('1') if result is Zero
  public final int YFpos = 5; // bit 5 of Flag Reg. ; Undocumented/Unused; copy of bit 5 of the result
  public final int HFpos = 4; // bit 4 of Flag Reg. ; Half-Carry of an addition/substraction (from bit 3 to 4); Used for BCD correction with DAA
  public final int XFpos = 3; // bit 3 of Flag Reg. ; Undocumented/Unused; copy of bit 3 of the result
  public final int PVFpos = 2; // bit 2 of Flag Reg. ; Parity of the result (logical); can also be VF (arithmetics), 2-complement signed overflow from range [-127:128]).
  public final int NFpos = 1; // bit 1 of Flag Reg. ; Set to 0 if last operation was an addition or to 1 for a substraction; used for DAA
  public final int CFpos = 0; // bit 0 of Flag Reg. ; Carry Flag, set if there was a carry after the Most-Significant-Bit

  public final int LSB = 0;
  public final int MSB = 1;

  public final String[] condName = {"NZ", "Z", "NC", "C", "PO", "PE", "P", "M"};
  public final int cNZpos = 0; // Z=0
  public final int cZpos  = 1; // Z=1
  public final int cNCpos = 2; // C=0
  public final int cCpos  = 3; // C=1
  public final int cPOpos = 4; // P/V=0
  public final int cPEpos = 5; // P/V=1
  public final int cPpos  = 6; // S=0
  public final int cMpos  = 7; // S=1

  int[] reg8b = new int[this.regLen]; // B, C, D, E, H, L, __(HL)__, A, F, I, R;
  int[] regPrime = new int[this.regPrimeLen]; // Bprime, Cprime, Dprime, Eprime, Hprime, Lprime, __, Aprime, Fprime;
  int[] specialReg = new int[this.speRegLen]; // PC (Program counter), SP (Stack Pointer, Special Purpose Registers);
  int[] reg16b = new int[this.reg16bLen]; // BC, DE, HL, AF, IR, IX, IY
  int[] reg16bprime = new int[this.reg16bPrimeLen]; // BCp, DEp, HLp, AFp
  //int[] flags = new int[this.FlagsLen]; // S, Z, Y, H, X, P/V, N, C

  int IFF1, IFF2; // Interrupts
  int IM; // Interrupt Mode

  boolean breakMode = false;
  int breakPoint = 0x0000;

  // =============================================================
  Registers () {
    this.PowerOnDefault();
  }

  void PowerOnDefault () {
    for (int i = 0; i < this.reg8b.length; i++) {
      this.reg8b[i] = 0x00; // B, C, D, E, H, L, __(HL)__, A, F, R, I;
    }
    for (int i = 0; i < this.regPrime.length; i++) {
      this.regPrime[i] = 0x00; // Bprime, Cprime, Dprime, Eprime, Hprime, Lprime, __, Aprime, Fprime;
    }
    this.specialReg[this.PCpos] = 0x0000; // PC (Program counter)
    this.specialReg[this.SPpos] = 0x0000; // SP (Stack Pointer, Special Purpose Registers)

    this.IFF1 = 0;
    this.IFF2 = 0;
    this.IM = 0;
  }

  // =============================================================
  int getFlagBit (int i) {
    return ((this.reg8b[this.Fpos] >> i) & 0x01);
  }

  int getCF () {
    return this.getFlagBit(this.CFpos);
  }

  void writeCF (int c) {
    this.writeFlagBit(this.CFpos, c);
  }

  void writeZF (int z) {
    this.writeFlagBit(this.ZFpos, z);
  }

  void writeHF (int h) {
    this.writeFlagBit(this.HFpos, h);
  }

  // ---------------------------------------------
  void setFlags (int a, int b, int c, int d, int e, int f, int g, int h) {
    this.reg8b[this.Fpos] = (((a & 0x01) << 7) + ((b & 0x01) << 6) + ((c & 0x01) << 5) + ((d & 0x01) << 4) + ((e & 0x01) << 3) + ((f & 0x01) << 2) + ((g & 0x01) << 1) + ((h & 0x01) << 0));
  }

  void setFlagBit (int bitnb) {
    this.reg8b[this.Fpos] |= (0x01 << bitnb);
  }

  void resetFlagBit (int bitnb) {
    this.reg8b[this.Fpos] &= ~(0x01 << bitnb);
  }

  void writeFlagBit (int bitnb, int v) {
    this.resetFlagBit(bitnb);
    this.reg8b[this.Fpos] |= ((v & 0x01) << bitnb);
  }

  void toggleFlagBit (int bitnb) {
    this.reg8b[this.Fpos] ^= (0x01 << bitnb);
  }

  int readFlagByte () {
    return this.reg8b[this.Fpos];
  }

  // =============================================================

  void setPC (int val16) {
    this.specialReg[this.PCpos] = (val16 & 0xFFFF);
  }

  int getPC () {
    return (this.specialReg[this.PCpos] & 0xFFFF);
  }

  void setSP (int val16) {
    this.specialReg[this.SPpos] = (val16 & 0xFFFF);
  }

  int getSP () {
    return (this.specialReg[this.SPpos] & 0xFFFF);
  }

  void setBKPOn () {
    this.breakMode = true;
  }

  void setBKPOff () {
    this.breakMode = false;
  }

  void setBKP (int breakpoint) {
    this.breakPoint = (breakpoint & 0xFFFF);
    this.setBKPOn();
  }

  boolean testCondFlag (int cond) {
    if (cond == this.cNZpos) {
      return (this.getFlagBit(this.ZFpos) == 0);
    } else if (cond == this.cZpos) {
      return (this.getFlagBit(this.ZFpos) == 1);
    } else if (cond == this.cNCpos) {
      return (this.getFlagBit(this.CFpos) == 0);
    } else if (cond == this.cCpos) {
      return (this.getFlagBit(this.CFpos) == 1);
    } else if (cond == this.cPOpos) {
      return (this.getFlagBit(this.PVFpos) == 0);
    } else if (cond == this.cPEpos) {
      return (this.getFlagBit(this.PVFpos) == 1);
    } else if (cond == this.cPpos) {
      return (this.getFlagBit(this.SFpos) == 0);
    } else {
      return (this.getFlagBit(this.SFpos) == 1);
    }
  }

  // =============================================================
  void update () {
    this.reg16b[this.AFpos] = (this.reg8b[this.Apos] << 8) + this.reg8b[this.Fpos];
    this.reg16b[this.BCpos] = (this.reg8b[this.Bpos] << 8) + this.reg8b[this.Cpos];
    this.reg16b[this.DEpos] = (this.reg8b[this.Dpos] << 8) + this.reg8b[this.Epos];
    this.reg16b[this.HLpos] = (this.reg8b[this.Hpos] << 8) + this.reg8b[this.Lpos];
    this.reg16b[this.IRpos] = (this.reg8b[this.Ipos] << 8) + this.reg8b[this.Rpos];
    this.reg16bprime[this.AFpos] = (this.regPrime[this.Apos] << 8) + this.regPrime[this.Fpos];
    this.reg16bprime[this.BCpos] = (this.regPrime[this.Bpos] << 8) + this.regPrime[this.Cpos];
    this.reg16bprime[this.DEpos] = (this.regPrime[this.Dpos] << 8) + this.regPrime[this.Epos];
    this.reg16bprime[this.HLpos] = (this.regPrime[this.Hpos] << 8) + this.regPrime[this.Lpos];
  }

  // =============================================================
  String getRegStatTitle () {
    return "PC   SP   A F  B C  D E  H L  I R  IX   IY   ApFp BpCp DpEp HpLp";
  }

  String logFlagBits() {
    String flagstr = "b";
    for (int i = 7; i >= 0; i--) {
      flagstr += (this.reg8b[this.Fpos] >> i) & 0x01;
    }
    return flagstr;
  }

  String getRegStat () {
    String t = "";
    t += hex(this.specialReg[this.PCpos], 4) + " ";
    t += hex(this.specialReg[this.SPpos], 4) + " ";
    t += hex(this.reg16b[this.AFpos], 4) + " ";
    t += hex(this.reg16b[this.BCpos], 4) + " ";
    t += hex(this.reg16b[this.DEpos], 4) + " ";
    t += hex(this.reg16b[this.HLpos], 4) + " ";
    t += hex(this.reg16b[this.IRpos], 4) + " ";
    t += hex(this.reg16b[this.IXpos], 4) + " ";
    t += hex(this.reg16b[this.IYpos], 4) + " ";
    t += hex(this.reg16bprime[this.AFpos], 4) + " ";
    t += hex(this.reg16bprime[this.BCpos], 4) + " ";
    t += hex(this.reg16bprime[this.DEpos], 4) + " ";
    t += hex(this.reg16bprime[this.HLpos], 4);
    return t;
  }
  
}