import processing.sound.*;

WhiteNoise noise;
SqrOsc[] sqOscChan;
Env env;

// Oscillator select value (0: PortA (left), 1: PortB (center=both-left-and-right), 2: PortC (right)
int channel;
final int MAXNBCHAN = 3;

// Oscillator(s) variables
float freq = 55; // Hz
float volume = 0.5; // amplitude Normalisée
final float MODULATION = 0.0; // utilisé pour la modulation; ici 0
float[] PANPOSITION = {-1.0, 0.0, 1.0}; // -1: left, 0: center, +1: right

// Envelope variables
float attackTime;
float sustainTime;
float sustainLevel;
float releaseTime;

float duration; // in ms
float trigger;

void setup () {
  size(640, 360);
  sqOscChan = new SqrOsc[MAXNBCHAN];
  for (int i = 0; i < MAXNBCHAN; i++) {
    sqOscChan[i] = new SqrOsc(this);
    sqOscChan[i].add(MODULATION);
    sqOscChan[i].pan(PANPOSITION[i]);
    sqOscChan[i].play(440, 0.0);
  }
  env = new Env(this);
  noise = new WhiteNoise(this);

  attackTime = 0.01; // durée pour atteindre le niveau max
  sustainTime = 0.3; // longeur de la note stable
  sustainLevel = 0.6; // niveau lors du sustain
  releaseTime = 0.2; // durée pour que le volume chute à 0 après le sustain

  trigger = 0;
  duration = 1000; // ms
  //noise.play(0.02, 0, 0);
}


void draw () {
  background(0);
  if (millis() > trigger) {
    sqOscChan[0].stop();
    sqOscChan[0].play();   
    sqOscChan[0].freq(freq);
    sqOscChan[0].amp(volume); // .stop();

    sqOscChan[2].stop();
    sqOscChan[2].play();
    sqOscChan[2].freq(freq*2);
    sqOscChan[2].amp(volume); // .stop();

    trigger = millis() + duration;
    freq *= 2; // up an octave
    freq = (freq > 1000) ? 55.0 : freq;
  }
}