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
    this.R = (tmp & 0x80) | ((tmp + n) & 0x7F); // only 7 lsb increment; bit 7 stays the same (can me modified by the LD R, A instructions);
  }

  int getR () {
    return this.R;
  }

  void setR (int r) {
    this.R = r & 0xFF;
  }
}