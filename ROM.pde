// ROM

class ROM {
  int[] data;
  int addr;
  String id;
  String fileName;

  ROM (String tid, String romFileName) {
    this.id = tid;
    this.data = new int[16 * 1024]; // 16kB of memory
    this.addr = 0x0000;
    this.fileName = romFileName;
    if (romFileName == null) {
      this.data[0] = 0x00;
    } else {
      this.loadRom();
    }
  }

  void loadRom () {
    byte[] bytes = loadBytes("data/ROM/" + this.fileName);
    println("Loading ROM : " + this.fileName);
    if (bytes == null) {
      println(this.fileName + " n'existe pas!");
    } else {
      for (int i = 0; i < bytes.length; i++) { 
        // bytes are from -128 to 127, this converts to 0 to 255
        this.data[i] = bytes[i] & 0xff;
      }
      log.logln("ROM " + this.id + " loaded with file " + this.fileName);
    }
  }
}