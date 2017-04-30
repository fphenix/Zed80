// used by class D7

class DataBlock {
  int block;
  int halfblock;
  ArrayList<Integer> data = new ArrayList<Integer>();

  DataBlock (int b, int h, ArrayList<Integer> d) {
    this.block = b;
    this.halfblock = h;
    for (int i = 0; i < d.size(); i++) {
      this.data.add(d.get(i));
    }
  }

  // return true if this object is the one having the block and halfblock numbers passed in
  boolean isTheOne (int b, int h) {
    return ((this.block == b) && (this.halfblock == h));
  }
}