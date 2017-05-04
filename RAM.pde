// RAM

class RAM {
  int[] data;
  int addr;

  RAM () {
    this.data = new int[64 * 1024]; // 64kB of memory
    this.addr = 0x0000;
  }
  
}