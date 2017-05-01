// Used by class Opcodes

class Cycles {
  int P; // Machine cycles, 1 (or 2) per instructions; the opcodes with 2 M cycles are the ones with an opcode prefix: EDxx, CBxx, DDxx, FDxx, DDCBxx, FDCBxx.
  int M; // Machine cycles, 1 (or 2) per instructions; the opcodes with 2 M cycles are the ones with an opcode prefix: EDxx, CBxx, DDxx, FDxx, DDCBxx, FDCBxx.
  int T; // T-States, number of clock period
  int R; // refresh cycles

  Cycles () {
    this.M = 0;
    this.T = 0;
    this.R = 0;
  }

  void countM (int n) {
    this.M += n;
  }

  void countT (int n) {
    this.T += n;
  }

  // increases everytime the CPU fetches an opcode or opcode prefix.
  void countR (int n) {
    int tmp = this.R;
    this.R = ((tmp + n) & 0x7F) | (tmp & 0x80); // only 7 lsb increment; bit 7 stays the same (can me modified by the LD R, A instructions);
  }

  int getR () {
    return this.R;
  }
}