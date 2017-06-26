// Programable Sound Generator AY-3-8912
// Canal A : gauche, canal B : milieu, canal C : droite
//
// PPI 0xF4 : Data (Son et Clavier)
// PPI 0xF7 : Contrôle
// PPI 0xF6 : Selection PSG
//
/* Pour le Port 0xF6:
 Bit   Description
 7   BDIR (Bus DIRection, signal PSG, voir ci-dessous)
 6   BC1 (Bus Control 1, signal PSG, voir ci-dessous
 5   Data write (signal cassette)
 4   Moteur cassette (signal cassette, 1=marche / 0=arrêt)
 3!0 Sélection numéro de ligne clavier (voir PPI)
 avec :
 Fonctions des bits 7 et 6 du port &F6xx                 BDIR   BC1
 Validation (le PSG valide l'opération précédente)         0   0
 Read Data (le PSG envoie une valeur à lire sur &F4xx)     0   1
 Write Data (le PSG récupère la valeur placée sur &F4xx)   1   0
 Select AY register (le PSG sélectionne le numéro          1   1 
 de registre placé sur &F4xx)
 */
import processing.sound.*;

class PSG {
  Z80 z80; // ref

  public final int psgReg_PER_A_LSB = 0;
  public final int psgReg_PER_A_MSB = 1;
  public final int psgReg_PER_B_LSB = 2;
  public final int psgReg_PER_B_MSB = 3;
  public final int psgReg_PER_C_LSB = 4;
  public final int psgReg_PER_C_MSB = 5;
  public final int psgReg_PER_NOISE = 6;
  public final int psgReg_MIX_CTRL  = 7;
  public final int psgReg_VOLUME_A = 8;
  public final int psgReg_VOLUME_B = 9;
  public final int psgReg_VOLUME_C = 10;
  public final int psgReg_PER_HARDENV_LSB = 11;
  public final int psgReg_PER_HARDENV_MSB = 12;
  public final int psgReg_SHAPE_HARDENV = 13;
  public final int psgReg_EXTDATA_PORTA = 14; // receives data from Keyboard & Joystick
  public final int psgReg_EXTDATA_PORTB = 15; // not used on CPC
  private final int nbRegs = 16;

  public final int freq4MHzDiv64  = 62500; //  4MHz/64
  public final int freq4MHzDiv256 = 15625; //  4MHz/256

  public final int CHANNEL_A = 0;
  public final int CHANNEL_B = 1;
  public final int CHANNEL_C = 2;
  public final int NOISE_A = 3;
  public final int NOISE_B = 4;
  public final int NOISE_C = 5;
  private final int NBCHANNELS = 3;

  public final float VOLMAX = 1.0;
  final float MODULATION = 0.0; // utilisé pour la modulation; ici 0
  final float[] PANPOSITION = {-1.0, 0.0, 1.0}; // -1: left (A),   0: center (B),   +1: right (C)

  int[] regPSG = new int[this.nbRegs]; // 16 reg for PPI access of the PSG
  String[] regComment = new String[this.nbRegs];

  WhiteNoise[] noise;
  SqrOsc[] sqOscChan;
  Env env; // ASR Envelope

  // Envelope variables
  float attackTime;
  float sustainTime;
  float sustainLevel;
  float releaseTime;

  float duration; // in ms
  float trigger;

  float[] channelVolume = new float[NBCHANNELS];
  int[] channelToneFreq = new int[NBCHANNELS];
  boolean[] envOnOff = new boolean[NBCHANNELS];
  int envelopeToneFreq;
  int volumeEnvelopeShape;
  boolean[] mixer = new boolean[(NBCHANNELS+NBCHANNELS)]; // channels + noise channels
  int noiseToneFreq;

  // ****************************************************************************************
  PSG (PApplet top) {
    this.init();
    this.sqOscChan = new SqrOsc[NBCHANNELS];
    this.noise = new WhiteNoise[NBCHANNELS];
    for (int i = 0; i < NBCHANNELS; i++) {
      this.sqOscChan[i] = new SqrOsc(top);
      this.sqOscChan[i].add(MODULATION);
      this.sqOscChan[i].pan(PANPOSITION[i]);
      // this.sqOscChan[i].play(440, 0.0);
      this.noise[i] = new WhiteNoise(top);
      this.noise[i].add(MODULATION);
      this.noise[i].pan(PANPOSITION[i]);
    }
    this.env = new Env(top);

    // ASR envelopp : Attack-Sustain-Release
    this.attackTime = 0.01; // durée pour atteindre le niveau max
    this.sustainTime = 0.3; // longeur de la note stable
    this.sustainLevel = 0.6; // niveau lors du sustain
    this.releaseTime = 0.2; // durée pour que le volume chute à 0 après le sustain
  }

  void setRef (Z80 z80ref) {
    this.z80 = z80ref;
  }

  // ****************************************************************************************
  void init () {
    this.regPSG[this.psgReg_PER_A_LSB] = 0x5A;
    this.regComment[this.psgReg_PER_A_LSB] = "PERIODE_A_LSB: Poids faible de la période sur 12 bits du son sur le canal A (gauche)";
    this.regPSG[this.psgReg_PER_A_MSB] = 0x00;
    this.regComment[this.psgReg_PER_A_MSB] = "PERIODE_A_MSB: Poids fort de la période sur 12 bits du son sur le canal A (gauche)";
    this.regPSG[this.psgReg_PER_B_LSB] = 0x5A;
    this.regComment[this.psgReg_PER_B_LSB] = "PERIODE_B_LSB: Poids faible de la période sur 12 bits du son sur le canal B (milieu)";
    this.regPSG[this.psgReg_PER_B_MSB] = 0x00;
    this.regComment[this.psgReg_PER_B_MSB] = "PERIODE_B_MSB: Poids fort de la période sur 12 bits du son sur le canal B (milieu)";
    this.regPSG[this.psgReg_PER_C_LSB] = 0x5A;
    this.regComment[this.psgReg_PER_C_LSB] = "PERIODE_C_LSB: Poids faible de la période sur 12 bits du son sur le canal C (droit)";
    this.regPSG[this.psgReg_PER_C_MSB] = 0x00;
    this.regComment[this.psgReg_PER_C_MSB] = "PERIODE_C_MSB: Poids fort de la période sur 12 bits du son sur le canal C (droit)";

    this.regPSG[this.psgReg_PER_NOISE] = 0x01;
    this.regComment[this.psgReg_PER_NOISE] = "BRUIT: Periode du générateur de bruit sur 5 bits";

    this.regPSG[this.psgReg_MIX_CTRL] = 0x3F;
    this.regComment[this.psgReg_MIX_CTRL] = "CONTROLE: registre de Contrôle Mixeur, '0' pour activer, b0,1 et 2: Canal A, B et C, b3,4 et 5: Bruit sur A, B et C; b6=0: Reg14 (clavier) en entrée; b7 unused";

    this.regPSG[this.psgReg_VOLUME_A] = 0x00;
    this.regComment[this.psgReg_VOLUME_A] = "VOLUME_A: Volume du canal A (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    this.regPSG[this.psgReg_VOLUME_B] = 0x00;
    this.regComment[this.psgReg_VOLUME_B] = "VOLUME_B: Volume du canal B (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    this.regPSG[this.psgReg_VOLUME_C] = 0x00;
    this.regComment[this.psgReg_VOLUME_C] = "VOLUME_C: Volume du canal C (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";

    this.regPSG[this.psgReg_PER_HARDENV_LSB] = 0x0D;
    this.regComment[this.psgReg_PER_HARDENV_LSB] = "PERIODE_HARD_ENV_LSB: Poids faible de la période de la courbe d'enveloppe";
    this.regPSG[this.psgReg_PER_HARDENV_MSB] = 0x00;
    this.regComment[this.psgReg_PER_HARDENV_MSB] = "PERIODE_HARD_ENV_MSB: Poids fort de la période de la courbe d'enveloppe";
    this.regPSG[this.psgReg_SHAPE_HARDENV] = 0x18;
    this.regComment[this.psgReg_SHAPE_HARDENV] = "SHAPE_HARD_ENV: forme de la courbe du générateur de courbes d'enveloppe (bit0:Hold, bit1:Alternate, bit2:Attack, bit3:Continue)";

    this.regPSG[this.psgReg_EXTDATA_PORTA] = 0x00;
    this.regPSG[this.psgReg_EXTDATA_PORTB] = 0x00;
    this.regComment[this.psgReg_EXTDATA_PORTA] = "KEYBOARD_A: gestion du clavier via le port A du PSG; cf PPI";
    this.regComment[this.psgReg_EXTDATA_PORTB] = "KEYBOARD_B: Réservé pour Gestion du clavier via le port B du PSG; NON CABLE SUR CPC!!!";
  }

  // ****************************************************************************************
  void updateRegs () {
    this.channelToneFreq[CHANNEL_A] = this.calcFreqHz(this.toneRegsToVal(this.psgReg_PER_A_LSB, this.psgReg_PER_A_MSB));
    this.channelToneFreq[CHANNEL_B] = this.calcFreqHz(this.toneRegsToVal(this.psgReg_PER_B_LSB, this.psgReg_PER_B_MSB));
    this.channelToneFreq[CHANNEL_C] = this.calcFreqHz(this.toneRegsToVal(this.psgReg_PER_C_LSB, this.psgReg_PER_C_MSB));

    this.noiseToneFreq = this.calcFreqHz(this.regPSG[this.psgReg_PER_NOISE] & 0x1F);

    this.mixer[CHANNEL_A] = this.mixOnOff(CHANNEL_A);
    this.mixer[CHANNEL_B] = this.mixOnOff(CHANNEL_B);
    this.mixer[CHANNEL_C] = this.mixOnOff(CHANNEL_C);
    this.mixer[NOISE_A] = this.mixOnOff(NOISE_A);
    this.mixer[NOISE_B] = this.mixOnOff(NOISE_B);
    this.mixer[NOISE_C] = this.mixOnOff(NOISE_C);

    //if bit 4 = 1 then ENVelope else fixed level amplitude
    if (this.regPSG[this.psgReg_VOLUME_A] < 0x10) {
      this.channelVolume[CHANNEL_A] = this.calcVol(this.regPSG[this.psgReg_VOLUME_A]);
      this.envOnOff[CHANNEL_A] = false;
    } else {
      this.envOnOff[CHANNEL_A] = true;
    }
    if (this.regPSG[this.psgReg_VOLUME_B] < 0x10) {
      this.channelVolume[CHANNEL_B] = this.calcVol(this.regPSG[this.psgReg_VOLUME_B]);
      this.envOnOff[CHANNEL_B] = false;
    } else {
      this.envOnOff[CHANNEL_B] = true;
    }
    if (this.regPSG[this.psgReg_VOLUME_C] < 0x10) {
      this.channelVolume[CHANNEL_C] = this.calcVol(this.regPSG[this.psgReg_VOLUME_C]);
      this.envOnOff[CHANNEL_C] = false;
    } else {
      this.envOnOff[CHANNEL_C] = true;
    }

    this.envelopeToneFreq = this.calcEnvFreqHz(this.regPSG[this.psgReg_PER_HARDENV_LSB] + (this.regPSG[this.psgReg_PER_HARDENV_MSB] << 8));
    // bits [3 to 0] = CONTinue, ATTack, ALTernate, HOLD
    this.volumeEnvelopeShape = this.regPSG[this.psgReg_SHAPE_HARDENV];
  }

  // ****************************************************************************************
  void playSounds () {
    float freq;
    float amp;
    for (int i = 0; i < NBCHANNELS; i++) {
      if (this.mixer[i]) {
        freq = this.channelToneFreq[i];
        if (this.envOnOff[i]) {
          amp = this.volumeEnvelopeShape; 
          //this.env.play(this.sqOscChan[i], this.attackTime, this.sustainTime, this.sustainLevel, this.releaseTime);
        } else {
          amp = this.channelVolume[i];
        }
        this.sqOscChan[i].play(freq, amp);
        psglog.logln("Sound canal " + i + " " + freq + " " +amp);
      }
      // noise
      if (this.mixer[i + NBCHANNELS]) {
        freq = this.noiseToneFreq;
        amp = this.channelVolume[i];
        this.noise[i].play(freq, amp);
        psglog.logln("Noise canal " + i + " " + freq + " " +amp);
      }
    }
  }

  // ****************************************************************************************
  void writePSGreg(int regnb, int val8) {
    this.regPSG[regnb & 0x0F] = val8 & 0xFF;
    psglog.logln("Write PSG reg #" + (regnb & 0x0F) + " : val = 0x" + hex(val8, 2) + " ; " + this.regComment[regnb & 0x0F]);
    log.logln(this.regComment[regnb & 0x0F] + "; WRITE value=0x" + hex(val8, 2));
    this.updateRegs();
    this.playSounds();
  }

  int readPSGreg(int regnb) {
    int val8 = this.regPSG[regnb & 0x0F] & 0xFF;
    if (regnb < psgReg_EXTDATA_PORTA) {
      psglog.logln("Read  PSG reg #" + (regnb & 0x0F) + " : val = 0x" + hex(val8, 2) + " ; " + this.regComment[regnb & 0x0F]);
    }
    log.logln(this.regComment[regnb & 0x0F] + "; READ value=0x" + hex(val8, 2));
    return val8;
  }

  // ****************************************************************************************
  // enables are active LOW, hence if a bit is 0, then the corresponding channel or noise is on, else it is off
  boolean mixOnOff (int bitnb) {
    return (((this.regPSG[this.psgReg_MIX_CTRL] >> bitnb) & 0x01) == 0) ? true : false;
  }

  int toneRegsToVal (int lsb, int msb) {
    return (this.regPSG[lsb] + ( (this.regPSG[msb] & 0x0F) << 8) );
  }

  float calcVol (int val) {
    return map((VOLMAX / pow(sqrt(2), (15-val))), 0.0, VOLMAX, 0.0, 1.0);
  }

  // periode in [1...4095] for regular tones (0 acts as 1)
  //         in [1..31] for noise
  int calcFreqHz (int periode) {
    return floor(1.0 * freq4MHzDiv64 / periode);
  }

  int calcEnvFreqHz (int periode) {
    return floor(1.0 * freq4MHzDiv256 / periode);
  }

  // ex: pour 440 Hz (note LA), il faut placer dans les registres de période:
  // 62500/440 = 142 = 0x008E, d'où 0x8E dans reg0 et 0x00 dans reg1 par exemple.
  int calcPeriode (int freq) {
    return floor(1.0 * freq4MHzDiv64 / freq);
  }

  int calcHardEnvPeriod (int val) {
    return floor(125000.0 * val / 16.0);
  }

  int calcHardEnvVal (int periode) {
    return floor(125000.0 * periode / 16.0);
  }

  // note: 1, 2, 3 ... à 12 => Do, Do#, Ré, ... à Si
  // octave de -3 (grave) à 4 (aigu), avec 0, l'octave ayant le LA int (440Hz)
  float calcNoteFreq(int note, int octave) {
    float exp = octave + ((note - 10.0) / 12.0);
    return 440.0 * pow(2, exp);
  }

  float calcNotePeriode(int note, int octave) {
    return floor(1.0 / this.calcNoteFreq(note, octave));
  }
}

// ***************************************************************************************************
/* Exemple de protocle:
 OUT &F4xx,numéro de registre
 OUT &F6xx,&C0                 ' Lecture du registre par le PSG
 OUT &F6xx,0                   ' Validation de la donnée
 OUT &F4xx,valeur
 OUT &F6xx,&80                 ' Lecture du data par le PSG
 OUT &F6xx,0                   ' Validation de la donnée
 Ou en utilisant le vecteur:
 ld a,registre
 ld c,valeur
 call &bd34
 */