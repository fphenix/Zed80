class Log {
  PrintWriter log;
  String logname;
  boolean mode; // on (true) or off (false)
  int lines;
  int logfromaddr;
  int pc;
  int id;

  // ********************************************************************
  Log () {
    this.id = 0;
    this.construct("LogFile.txt");
  }

  Log (String lname) {
    this.id = 0;
    this.construct(lname);
  }

  void construct(String lname) {
    this.logname = lname;
    this.log = createWriter("data/Logs/" + lname); // Create a new file in the sketch directory
    this.lines = 0;
    this.logfromaddr = -2;
    this.pc = -1;
    this.logln("MEM   : PCADDR : OPCODES     : DISASM                ; SZ-H-PNC ; PC  |SP  |B C |D E |H L |A F |I R |IX  |IY    ; Comment");
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
    this.mode |= (this.logfromaddr == this.pc);
  }

  // ********************************************************************
  void logIt (String str, boolean ln) {
    if (this.mode) { //if (this.mode == true)
      this.isNextOneReq();
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

  void isNextOneReq () {
    if (this.lines >= 1000000) {
      this.logFlush();
      this.logClose();
      String fn = this.logname;
      String[] nameext = split(fn, '.');
      String[] namenb = split(nameext[0], '_');
      this.id++;
      this.logname = namenb[0] + "_" + str(this.id) + "." + nameext[1];
      this.construct(this.logname);
    }
  }

  // ********************************************************************
  void logFlush () {
    this.log.flush(); // Writes the remaining data to the file
  }

  void logClose () {
    this.log.close(); // Writes the remaining data to the file
  }
}