// Programable Sound Generator
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
  int[] regPSG = new int[this.nbRegs]; // 16 reg for PPI access of the PSG
  String[] regComment = new String[this.nbRegs];
  
  SqrOsc squareOsc;

  PSG () {
    this.init();
    //this.squareOsc = new SqrOsc();
  }

  void setRef (Z80 z80ref) {
    this.z80 = z80ref;
  }
  
  void init () {
    this.regComment[this.psgReg_PER_A_LSB] = "PERIODE_A_LSB: Poids faible de la période sur 12 bits du son sur le canal A (gauche)";
    this.regComment[this.psgReg_PER_A_MSB] = "PERIODE_A_MSB: Poids fort de la période sur 12 bits du son sur le canal A (gauche)";
    this.regComment[this.psgReg_PER_B_LSB] = "PERIODE_B_LSB: Poids faible de la période sur 12 bits du son sur le canal B (milieu)";
    this.regComment[this.psgReg_PER_B_MSB] = "PERIODE_B_MSB: Poids fort de la période sur 12 bits du son sur le canal B (milieu)";
    this.regComment[this.psgReg_PER_C_LSB] = "PERIODE_C_LSB: Poids faible de la période sur 12 bits du son sur le canal C (droit)";
    this.regComment[this.psgReg_PER_C_MSB] = "PERIODE_C_MSB: Poids fort de la période sur 12 bits du son sur le canal C (droit)";
    this.regComment[this.psgReg_PER_NOISE] = "BRUIT: Periode du générateur de bruit sur 5 bits";
    this.regComment[this.psgReg_MIX_CTRL] = "CONTROLE: registre de Contrôle Mixeur, '0' pour activer, b0,1 et 2: Canal A, B et C, b3,4 et 5: Bruit sur A, B et C; b6: Reg14 (clavier) en entrée";
    this.regComment[this.psgReg_VOLUME_A] = "VOLUME_A: Volume du canal A (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    this.regComment[this.psgReg_VOLUME_B] = "VOLUME_B: Volume du canal B (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    this.regComment[this.psgReg_VOLUME_C] = "VOLUME_C: Volume du canal C (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    this.regComment[this.psgReg_PER_HARDENV_LSB] = "PERIODE_HARD_ENV_LSB: Poids faible de la période de la courbe d'enveloppe";
    this.regComment[this.psgReg_PER_HARDENV_MSB] = "PERIODE_HARD_ENV_MSB: Poids fort de la période de la courbe d'enveloppe";
    this.regComment[this.psgReg_SHAPE_HARDENV] = "SHAPE_HARD_ENV: forme de la courbe du générateur de courbes d'enveloppe (bit0:Hold, bit1:Alternate, bit2:Attack, bit3:Continue)";
    this.regComment[this.psgReg_EXTDATA_PORTA] = "KEYBOARD_A: gestion du clavier via le port A du PSG; cf PPI";
    this.regComment[this.psgReg_EXTDATA_PORTB] = "KEYBOARD_B: Réservé pour Gestion du clavier via le port B du PSG; NON CABLE SUR CPC!!!";
  }
  
  void writePSGreg(int regnb, int val8) {
    this.regPSG[regnb & 0x0F] = val8 & 0xFF;
    log.logln(this.regComment[regnb & 0x0F] + "; WRITE value=0x" + hex(val8, 2));
  }
  
  int readPSGreg(int regnb) {
    int val8 = this.regPSG[regnb & 0x0F] & 0xFF;
    log.logln(this.regComment[regnb & 0x0F] + "; READ value=0x" + hex(val8, 2));
    return val8;
  }
  
  int calcFreqHz (int periode) {
      return floor(62500.0 / periode);
  }
  
  // ex: pour 440 Hz (note LA), il faut placer dans les registres de période:
  // 62500/440 = 142 = 0x008E, d'où 0x8E dans reg0 et 0x00 dans reg1 par exemple.
  int calcPeriode (int freq) {
      return floor(62500.0 / freq);
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