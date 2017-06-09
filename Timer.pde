class Timer {
  int period;
  boolean enabled;
  int interrupt;  
  float startTick = 0;
  float currentTick = 0;
  float timelength;
  int count;

  Timer (int p) { // ex: Timer(300) for a 1/300th of a second timer
    this.period = p;
    this.timelength = 1000.0/p;
    this.enabled = false;
    this.interrupt = 0;
  }

  void enableTimer() {
    this.enabled = true;
    this.count = 0;
    this.currentTick =  millis();
    this.startTick = this.currentTick;
  }

  void disableTimer() {
    this.enabled = false;
  }

  void clearInt () {
    this.interrupt = 0;
  }

  int getInt () {
    return this.interrupt;
  }

  void runTimer() {
    this.count++;
    this.currentTick =  millis();
    if (this.currentTick > (this.startTick + this.timelength)) {
      this.interrupt = 1;
      this.enableTimer();
    }
  }
}