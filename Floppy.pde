/* Floppy Disc Controller UPD765A */
class Floppy {
  D7 diskette;

  String d7Name;
  byte fileData[];
  int fileSize;

  int   fdcStatusReg = 0x80; // Main status register for Floppy Disc Controller
  int[] secondaryStatusRegs = new int[7]; // ST0 to ST6 registers
  int   regMotorControl = 0;

  int data;

  final int INSTRUCTION = 0;
  final int INTERPRETATION = 1;
  final int EXECUTION = 2;
  final int RESULTAT = 3;
  int phase; 

  int driveIds; // bit2 = n° de tete; bits[0:1] = n° de lecteur (0 à 3)
  int head;
  int drive;  

  final int TRACKMAX = 42;
  final int SECTORMAX = 11;
  final int SIZEMAX = 512;
  int[][][] discData = new int[TRACKMAX][SECTORMAX][SIZEMAX];
  int[][][] sectorInfo = new int[TRACKMAX][SECTORMAX][4];
  final int DISCHEADERLENGTH = 256;
  final int TRKHEADERLENGTH = 256;
  int[] discHeader = new int[DISCHEADERLENGTH];
  int[] trkHeader = new int[TRKHEADERLENGTH];
  int[] discTracks = new int[TRACKMAX-2];

  int posInSector = 0;
  int sectorStart;
  int sectorEnd;
  int discNbTracks;
  int discTrack;

  int command = 0;
  int motorOn = 0;

  // ---------------------------------------------------------------------------
  // LIST OF COMMANDS:
  final int INSTR_TRKDELAY = 0x03; 
  final int PARAM_TRKDELAY = 2; // 8b'dddd0000 et 0x00 
  final int RET_TRKDELAY = 0;

  final int INSTR_QUERYSTATE = 0x04 ; 
  final int PARAM_QUERYSTATE = 1; // ID lecteur
  final int RET_QUERYSTATE = 1; // ST3

  final int INSTR_RECALIBRAGE = 0x07 ; // instruction n° 7
  final int PARAM_RECALIBRAGE = 1; // ID lecteur
  final int RET_RECALIBRAGE = 0; // none

  final int INSTR_INTSTATE = 0x08 ; 
  final int PARAM_INTSTATE = 0; // none
  final int RET_INTSTATE = 2; // ST0, N° de piste en cours

  final int INSTR_SEEKTRACK = 0x0F ; 
  final int PARAM_SEEKTRACK = 2; // ID lecteur, n° Piste
  final int RET_SEEKTRACK = 0; // none

  final int INSTR_LECTURETRK = 0x42; 
  final int PARAM_LECTURETRL = 8; 
  final int RET_LECTURETRK = 7;

  final int INSTR_LECTURESEC = 0x46; 
  final int INSTR_MTLECTURESEC = 0xC6; // multitrack
  final int PARAM_LECTURESEC = 7; 
  final int RET_LECTURESEC = 7;

  final int INSTR_ECRITURESEC = 0x45; 
  final int INSTR_MTECRITURESEC = 0xC5; // multitrack
  final int PARAM_ECRITURESEC = 8; 
  final int RET_ECRITURESEC = 7;

  final int INSTR_FORMAT = 0x4D ; 
  final int PARAM_FORMAT = 5; // ID lecteur, taille secteur, nb secteurs/piste, Octet de séparation ID/data, Octet de remplissage du secteur
  final int RET_FORMAT = 7; // ST0,1,2, n° piste en cours, tete en cours, nom secteur en cours, taille secteur en cours

  final int INSTR_IDSECTSUIV = 0x4A; 
  final int PARAM_IDSECTSUIV = 1; // ID lecteur 
  final int RET_IDSECTSUIV = 7;
  // ------------------------------------------------------------------------------

  Floppy (String dname) {
    this.d7Name = dname;
  }

  Floppy () {
    //
  }

  // Read the Main Status Register
  int readStatus () { // 0xFB7E(RD)
    return this.fdcStatusReg;
  }

  // Read Data 
  int readData () { // 0xFB7F (RD)
    return this.readStateMachine();
  }

  // write Data
  void writeData (int dta) { // 0xFB7E et FB7F (WR)
    this.writeStateMachine(dta);
  }

  // Write Motot Control Register
  void writeMotorCtrl(int dta) { // 0xFA7E & FA7F (WR)
    // tout ou rien : soit on allume tous les moteurs soit on les eteints tous
    this.motorOn = dta & 0x01;
  }

  // ---------------------------------------------------------
  // PRIMARY STATUS REG : this.fdcStatusReg
  // b7 : data Port Waiting : 1 si Port de données en attente
  // b6 : data Direction : 1 : FDC attend que le Z80 lise les data; 0: FDC attend les data venant du Z80
  // b5 : phase Stat : 1: Phase d'instruction commencée; 0: Phase de résultat commencée
  // b4 : state :  1: Instruction en cours; 0: FDC "pret"
  // b[3:0]: drives On/Off :  si un bit à '1', le lecteur correspondant au bit est en train de déplacer sa tête de lecture/écriture
  // ---------------------------------------------------------
  // SECONDARY STAT REGs : this.secondaryStatusRegs[n] ; n 0 to 6
  // ST0 :  
  // b[7:6] : b'11 : Disquette éjectée en cours d'opération, b'10 : Instruction inconnue; b'0x : instruction achévée avec Succès
  // b[5] 1 = instruction achévée
  // b[4] : 1 : erreur mécanique ou échec du recalibrage
  // b[3] : lecteur ou tête indisponible
  // b[2,1:0] : tete en cours et n° lecteur en cours, c'est à dire lecteur ID
  //
  // ST1 :
  // b[7] : 1 : secteur de fin d'accès n'existe pas
  // b[6] : unused
  // b[5] : erreur de checksum dans un secteur
  // b[4] : 1: Z80 a trop attendu
  // b[3] : unused
  // b[2] : 1 si secteur de début d'accès n'existe pas ou ID secteur illisible
  // b[1] : 1 : tentative d'écriture ou de formatage sur disquette protégée
  // b[0] : erreur de formatage sur le disque
  //
  // ST2 :
  // b7 : unused
  // b6 : 1 = secteur effacé a été rencontré
  // b5 : erreur de checksum dans données du secteur
  // b4 : n° de piste dans l'ID secteur ne correspond pas à la piste en cours
  // b3,2: voir "Scan"
  // b1 : n° de piste de l'ID = &FF
  // b0 : erreur de formatage sur une zone de données
  //
  // ST3:
  // b7 : lecteur en panne
  // b6 : Disquette protégée
  // b5 : tout est OK, lecteur prêt
  // b4 : tete en piste 0
  // b3 : 1= lecteur simple tete, 0: lecteur double tete
  // b2,1:0 : lecteur ID (n° tete et n° lecteur)
  int reading = 0;
  int endRead;
  int fdcInt = 0;
  int readParams = 0;
  int realStart;
  int discOn;
  int trackStart;
  int writeParams = 0;
  int[] paramData = new int[16];

  void writeStateMachine (int val) {
    if (this.writeParams > 0) {
      this.paramData[this.writeParams - 1] = val;
      this.writeParams--;
      if (this.writeParams == 0) {
        switch (this.command) {
        case INSTR_TRKDELAY : 
          this.fdcStatusReg = 0x80;
          break;

        case 0x04 :
          this.secondaryStatusRegs[3] = 0x60;
          if (this.discTrack == 0) {
            this.secondaryStatusRegs[3] |= 0x10;
          }
          this.fdcStatusReg = 0xD0;
          this.readParams = 1;
          break;

        case 0x06:
          this.trackStart = this.paramData[6];
          this.sectorStart = this.paramData[4] & 0x0F;
          this.sectorEnd = this.paramData[2] & 0x0F;
          this.realStart = 0;
          this.posInSector = 0;
          this.readParams = 1;
          this.reading = 1;
          this.fdcStatusReg = 0xF0;
          break;

        case 0x07 :
          this.fdcStatusReg = 0x80;
          this.discTrack = 0;
          this.fdcInt = 1;
          break;

        case 0x0A :
          this.fdcStatusReg |= 0x60;
          this.readParams = 7;
          break;

        case 0x0F :
          this.fdcStatusReg = 0x80;
          this.discTrack = this.paramData[0];
          this.fdcInt = 1;
          break;

        default :
          // nothing
        }
      }
    } else {
      this.command = val & 0x1F;
      switch (this.command) {
      case 0 :
      case 0x1F :
        return;  // Invalid

      case 0x03 : // 
        this.writeParams = 2;
        this.fdcStatusReg |= 0x10;
        break;

      case 0x04 : // drive status
        this.writeParams = 1;
        this.fdcStatusReg |= 0x10;
        break;

      case 0x06 : // read sector
        this.writeParams = 8;
        this.fdcStatusReg |= 0x10;
        this.discOn = 1;
        break;

      case 0x07 : // recalibrate
        this.writeParams = 1;
        this.fdcStatusReg |= 0x10;
        break;

      case 0x08 : // sens interrupt state
        this.secondaryStatusRegs[0] = 0x21;
        if (this.fdcInt == 0) {
          this.secondaryStatusRegs[0] |= 0x80;
        } else {
          this.fdcInt = 0;
        }
        this.readParams = 2;
        this.fdcStatusReg |= 0xD0;
        break;

      case 0x0A :
        this.writeParams = 1;
        this.fdcStatusReg |= 0x10;
        break;

      case 0x0F :
        this.writeParams = 2;
        this.fdcStatusReg |= 0x10;
        break;

      default:
        // nothing;
      }
    }
  }

  int readStateMachine () {
    int databyte;
    switch (this.command) {
    case INSTR_QUERYSTATE :
      this.fdcStatusReg = 0x80;
      return this.secondaryStatusRegs[3];
      //break;

    case INSTR_LECTURESEC :
    case INSTR_MTLECTURESEC :
      if (this.reading > 0) {
        databyte = this.discData[this.discTrack][this.sectorStart-1][this.posInSector];
        this.posInSector++;
        if (this.posInSector == SIZEMAX) {
          if ((this.sectorStart & 0x0F) == (this.sectorEnd & 0x0F)) {
            this.reading = 0;
            this.readParams = PARAM_LECTURESEC;
            this.fdcStatusReg = 0xD0;
            this.endRead = 1;
            this.fdcInt = 1;
            this.discOn = 0;
          } else {
            this.posInSector = 0;
            this.sectorStart++;
            if ((this.sectorStart & 0x0F) == (this.discTracks[this.discTrack] + 1)) {
              if ((this.command & 0x80) > 0) { // MultiTrack
                this.discTrack++;
              }
              this.sectorStart = 0xC1;
            }
            this.realStart = 0;
            for (int sect = 0; sect < SECTORMAX; sect++) {
              if ((this.sectorInfo[this.trackStart][sect][2] & 0x0F) == (this.sectorStart & 0x0F)) {
                this.realStart = sect;
                break;
              }
            }
          }
        }
        return databyte;
      }
      this.readParams--;
      switch (this.readParams) {
      case 6 : 
        this.secondaryStatusRegs[0] = 0x40;
        this.secondaryStatusRegs[1] = 0x80;
        this.secondaryStatusRegs[2] = 0x00;
        return this.secondaryStatusRegs[0];
      case 5 : 
        return this.secondaryStatusRegs[1];
      case 4 : 
        return this.secondaryStatusRegs[2];
      case 3 : 
        return this.discTrack;
      case 2: 
        return 0x00;
      case 1 : 
        return this.sectorStart;
      default : 
        this.fdcStatusReg = 0x80; 
        return 0x02;
      }
      // break;

    case INSTR_INTSTATE :
      this.readParams--;
      if (this.readParams == 1) {
        return this.secondaryStatusRegs[0];
      }
      this.fdcStatusReg = 0x80; 
      return this.discTrack;
      // break;

    case INSTR_IDSECTSUIV :
      this.readParams--;
      switch(this.readParams) {
      case 6 : 
        return this.secondaryStatusRegs[0];
      case 5 : 
        return this.secondaryStatusRegs[1];
      case 4 : 
        return this.secondaryStatusRegs[2];
      case 3 : 
        return this.sectorInfo[this.discTrack][this.sectorStart][0];
      case 2 : 
        return this.sectorInfo[this.discTrack][this.sectorStart][1];
      case 1 : 
        return this.sectorInfo[this.discTrack][this.sectorStart][2];
      default : 
        this.fdcStatusReg = 0x80; 
        return this.sectorInfo[this.discTrack][this.sectorStart][3];
      }
      // break;

    default:
      return 0x00; // nothing right now
    }
  }

  void readFloppy (String fname) {
    println("Inserting Diskette : " +fname);
    this.diskette = new D7();
    this.discData = this.diskette.readFile(fname);
  }
}