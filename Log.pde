class Log {
  PrintWriter log;
  String logname;
  boolean mode; // on (true) or off (false)
  int lines;

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
  }

  // ********************************************************************
  void logModeON () {
    this.mode = true;
  }

  void logModeOFF () {
    this.mode = false;
  }

  boolean getLogMode () {
    return this.mode;
  }

  // ********************************************************************
  void logln (String str) {
    if (this.mode) {
      this.log.println(str);
      this.lines++;
      if ((this.lines % 10) == 0) {
        this.logFlush();
      }
    }
  }

  void lognnl (String str) {
    if (this.mode) {
      this.log.print(str);
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