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

class PSG {
  Z80 z80; // ref
  
  int[] reg = new int[16]; // 16 reg for PPI access of the PSG
  String[] regComment = new String[16];

  PSG () {
  }

  void setRef (Z80 z80ref) {
    this.z80 = z80ref;
  }
  
  void init () {
    regComment[0] = "PERIODE_A_LSB: Poids faible de la période sur 12 bits du son sur le canal A (gauche)";
    regComment[1] = "PERIODE_A_MSB: Poids fort de la période sur 12 bits du son sur le canal A (gauche)";
    regComment[2] = "PERIODE_B_LSB: Poids faible de la période sur 12 bits du son sur le canal B (milieu)";
    regComment[3] = "PERIODE_B_MSB: Poids fort de la période sur 12 bits du son sur le canal B (milieu)";
    regComment[4] = "PERIODE_C_LSB: Poids faible de la période sur 12 bits du son sur le canal C (droit)";
    regComment[5] = "PERIODE_C_MSB: Poids fort de la période sur 12 bits du son sur le canal C (droit)";
    regComment[6] = "BRUIT: Periode du générateur de bruit sur 5 bits";
    regComment[7] = "CONTROLE: registre de Contrôle, '0' pour activer, b0,1 et 2: Canal A, B et C, b3,4 et 5: Bruit sur A, B et C; b6: Reg14 (clavier) en entrée";
    regComment[8] = "VOLUME_A: Volume du canal A (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    regComment[9] = "VOLUME_B: Volume du canal B (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    regComment[10] = "VOLUME_C: Volume du canal C (bits [3:0]) et Selecteur ON/OFF d'enveloppe (bit 4); niveau logarithmique";
    regComment[11] = "PERIODE_HARD_ENV_LSB: Poids faible de la période de la courbe d'enveloppe";
    regComment[12] = "PERIODE_HARD_ENV_MSB: Poids fort de la période de la courbe d'enveloppe";
    regComment[13] = "SHAPE_HARD_ENV: forme de la courbe du générateur de courbes d'enveloppe (bit0:Hold, bit1:Alternate, bit2:Attack, bit3:Continue)";
    regComment[14] = "KEYBOARD_A: gestion du clavier via le port A du PSG; cf PPI";
    regComment[15] = "KEYBOARD_B: Réservé pour Gestion du clavier via le port B du PSG; NON CABLE SUR CPC!!!";
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