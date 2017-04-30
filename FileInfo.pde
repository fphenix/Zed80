// used by class D7

class FileInfo {
  String filename;
  int loadadr;
  int flength;
  int startadr;
  int filetype;
  ArrayList<Byte> data = new ArrayList<Byte>();

  FileInfo (String fn, int ld, int len, int st, int ft) {
    this.filename = fn;
    this.setInfo(ld, len, st, ft);
  }

  FileInfo (String fn) {
    this.filename = fn;
    this.setInfo(0, 0, 0, 0);
  }

  void setInfo (int ld, int len, int st, int ft) {
    this.loadadr = ld;
    this.flength = len;
    this.startadr = st;
    this.filetype = ft;
  }
}