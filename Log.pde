class Log {
  PrintWriter log;
  String logname;
  boolean mode; // on (true) or off (false)
  int lines;
  int logfromaddr;
  int pc;

  // ********************************************************************
  Log () {
    this.construct("LogFile.txt");
  }

  Log (String lname) {
    this.construct(lname);
  }

  void construct(String lname) {
    this.logname = lname;
    this.log = createWriter("data/" + lname); // Create a new file in the sketch directory
    this.lines = 0;
    this.logfromaddr = -2;
    this.pc = -1;
  }

  // ********************************************************************
  void logModeON () {
    this.mode = true;
    this.logfromaddr = -2;
  }

  void logModeON (int addr) {
    this.mode = false;
    this.logfromaddr = addr;
  }

  void logModeOFF () {
    this.mode = false;
  }

  boolean getLogMode () {
    return this.mode;
  }

  void setPC (int tpc) {
    this.pc = tpc;
  }

  // ********************************************************************
  void logIt (String str, boolean ln) {
    println(this.mode, (this.logfromaddr == this.pc), hex(this.logfromaddr, 4), hex(this.pc, 4));
    if ((this.mode) || (this.logfromaddr == this.pc)) {
      print("****************************************************************************");
      this.mode = true;
      if (ln) {
        this.log.println(str);
      } else {
        this.log.print(str);
      }
      this.lines++;
      if ((this.lines % 10) == 0) {
        this.logFlush();
      }
    }
  }

  void logln (String str) {
    this.logIt(str, true);
  }

  void lognnl (String str) {
    this.logIt(str, false);
  }

  // ********************************************************************
  void logFlush () {
    this.log.flush(); // Writes the remaining data to the file
  }

  void logClose () {
    this.log.close(); // Writes the remaining data to the file
  }
}