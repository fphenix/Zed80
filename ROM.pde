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
    this.loadRom();
  }

  void loadRom () {
    byte[] bytes = loadBytes("data/" + this.fileName);
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

//        memory.setLowerROM(getRom("roms/OS6128.ROM", 0x4000));
//        memory.setUpperROM(0, getRom("roms/BASIC1-1.ROM", 0x4000));
//        memory.setUpperROM(7, getRom("roms/AMSDOS.ROM", 0x4000));
/*    public void setLowerROM(byte[] data) {
 setROM(9, data);
 }
 public void setUpperROM(int rom, byte[] data) {
 setROM(10 + (rom & 0x0f), data);
 }
 
 protected boolean setROM(int base, byte[] data) {
 if (data == null || data.length == 0) {
 freeMem(base, 16 * KB);
 return false;
 } else {
 base = getMem(base, 16 * KB);
 System.arraycopy(data, 0, mem, base, Math.min(16 * KB, data.length));
 return true;
 }
 }*/