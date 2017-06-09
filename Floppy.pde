/* Floppy Disc Controller UPD765A */
// 3'' floppy discs for CPC have:
// 1 record = 128 bytes
// 1 sector = 512 bytes (type 2)   (a "slice"); sector interleave 2:1; 360 sectors
// 1 block  = 2 sectors
// 1 track  = 9 sectors ; cylinder = track (but both heads)
// Single sided ; Double density (= 9 sectors / track) = MFM mode
// 40 or 41 tracks : System format: 169 Kbytes file capacity, Data format: 2Kb for Directory info, 178KB capacity)
class Floppy {
  D7 diskette;

  String d7Name;
  byte fileData[];
  int fileSize;

  final int STATREG_DATAPORTWAITING = 7; // bit 7; Data port waiting
  final int STATREG_FDCWAITINGFORZ80READ = 6; // bit 6, 1: FDC waits for Z80 to read data, else if 0, FDC waiting data from CPU
  final int STATREG_PHASEINSTRUCTION = 5; // bit 5, if 1: Instruction Phase, else PHASERESULTAT
  final int STATREG_INSTRUCTIONENCOURS = 4; // bit 4, Instruction en cours, else FDC ready
  final int STATREG_DRIVE1_BUSY = 1; // bit 0 : drive 0 busy (1) or ready (0)
  final int STATREG_DRIVE0_BUSY = 0; // bit 0 : drive 0 busy (1) or ready (0)

  int   fdcStatusReg; // Main status register for Floppy Disc Controller
  int[] secondaryStatusRegs = new int[7]; // ST0 to ST6 registers

  final int TRACKMAX = 40; // 0 à 39; catalogue (2KB, 64 entry max) : Piste0, secteurs 0xC1 à 0xC4 pour AmsDos. Catalogue en Piste 2 0x41 à 0x44 pour CP/M avec info system en Piste 0, secteur &41, &42, &48, &49 et Piste 1 secteur &41, &46, &42, &47, &43, &48, &44, &49, &45.
  final int SECTORMAX = 9; // 9
  final int SIZEMAX = 512; // type 2 used for CPC
  final int formatByte = 0xE5;
  int[][][] discData = new int[TRACKMAX][SECTORMAX][SIZEMAX];
  int[][][] sectorInfo = new int[TRACKMAX][SECTORMAX][4];
  final int DISCHEADERLENGTH = 256;
  final int TRKHEADERLENGTH = 256;
  int[] discHeader = new int[DISCHEADERLENGTH];
  int[] trkHeader = new int[TRKHEADERLENGTH];
  int[] discTracks = new int[TRACKMAX-2];


  int sectorStart = 0xC1; // 0xC1 : AmsDos; 0x41 : CP/M
  int sectorEnd;
  int discNbTracks;
  int discTrack = 0;
  boolean motorToggled = false;

  int data;
  int phase; 

  int command = 0x00;
  String cmdName = "";
  int drive = 0x00;  // b1:0 = 00 Drive A, 01 DB, 10 DC 11 DD
  int head;
  int driveId; // bit2 = n° de tete; bits[0:1] = n° de lecteur (0 à 3)
  int motorOn = 0;
  int motorCount = 0;
  int motorReady = 0;

  // ---------------------------------------------------------------------------
  // LIST OF COMMANDS:
  final int INSTR_LECTURETRK = 0x02; // lecture de piste entiere
  final String NAME_LECTURETRK = "Read Track";
  final int INSTR_ECRITURESEC = 0x05; // ecriture de secteur
  final String NAME_ECRITURESEC = "Write Sector(s)";
  final int INSTR_LECTURESEC = 0x06; // lecture de secteur
  final String NAME_LECTURESEC = "Read Sector(s)";
  final int INSTR_ECRITURESECEFF = 0x09;  // ecriture de secteur effacé
  final String NAME_ECRITURESECEFF = "Write Deleted Sector(s)";
  final int INSTR_LECTURESECEFF = 0x0C; // lecture de secteur effacé
  final String NAME_LECTURESECEFF = "Read Deleted Sector(s)";
  final int INSTR_SCANEQUAL = 0x11; // not yet supported
  final String NAME_SCANEQUAL = "Scan Equal";
  final int INSTR_SCALOWORNEQUAL = 0x19; // not yet supported
  final String NAME_SCALOWORNEQUAL = "Scan Low or Equal";
  final int INSTR_SCAHIGHORNEQUAL = 0x1D; // not yet supported
  final String NAME_SCAHIGHORNEQUAL = "Scan High or Equal";
  final int PARAM_REGULAR = 8; // DriveId, sector C, H, R, N, EOT, GPL, DTL 
  final int RET_REGULAR = 7; // ST0to2, Sector C, H, R, N

  final int INSTR_SPECIFYTRKDELAY = 0x03; 
  final String NAME_SPECIFYTRKDELAY = "Specify";
  final int PARAM_SPECIFYTRKDELAY = 2; // 8b'dddd0000 et 0x00 
  final int RET_NONE = 0; // none

  final int INSTR_QUERYSTATE = 0x04 ; // query drive status
  final String NAME_QUERYSTATE = "Sense Drive State";
  final int PARAM_QUERYSTATE = 1; // ID lecteur (0x00 pour drive A)
  final int RET_QUERYSTATE = 1; // ST3

  final int INSTR_RECALIBRAGE = 0x07 ; // instruction n° 7
  final String NAME_RECALIBRAGE = "Recalibrate";
  final int PARAM_RECALIBRAGE = 1; // ID lecteur
  // final int RET_NONE = 0; // none, mais va en piste 0

  final int INSTR_INTSTATUS = 0x08 ; // lecture interrupt
  final String NAME_INTSTATUS = "Sense Interrupt Status";
  final int PARAM_NONE = 0; // none
  final int RET_INTSTATUS = 2; // ST0, PCN: N° de piste en cours

  final int INSTR_IDSECTSUIV = 0x0A; // read id
  final String NAME_IDSECTSUIV = "Read Id";
  final int PARAM_IDSECTSUIV = 1; // ID lecteur 

  final int INSTR_FORMAT = 0x0D ; // format une piste
  final String NAME_FORMAT = "Format Track";
  final int PARAM_FORMAT = 5; // ID lecteur, N taille secteur Bytes/sector (type 2), SC nb secteurs/piste (9), Octet de séparation ID/data GAP3 (&52), D Octet de remplissage du secteur (&e5)

  final int INSTR_SEEKTRACK = 0x0F ; 
  final String NAME_SEEKTRACK = "Seek Track";
  final int PARAM_SEEKTRACK = 2; // ID lecteur, NCN n° Piste (41 max)
  final int RET_SEEKTRACK = 0; // none

  final int INSTR_VERSION = 0x10 ; 
  final String NAME_VERSION = "VERSION";
  final int RET_VERSION = 1; // 0x80 for 765A (ST0)

  // ------------------------------------------------------------------------------

  Floppy (String dname) {
    this.d7Name = dname;
    this.init();
  }

  Floppy () {
    this.init();
  }

  // ---------------------------------------------------------------------------------
  void init () {
    this.fdcStatusReg = 0x00; // but becomes 0x80 one line below!
    this.setBit_statReg(STATREG_DATAPORTWAITING); // b[7:6]= b'10 : FDC pret à recevoir
    this.fdcInterruptClear();
  }

  // ---------------------------------------------------------------------------------
  int setBit (int val, int bit) {
    return (val | (1 << bit)) & 0xFF;
  }

  int clearBit (int val, int bit) {
    return (val & (~(1 << bit))) & 0xFF;
  }

  void setBit_statReg (int bit) {
    this.fdcStatusReg = this.setBit(this.fdcStatusReg, bit);
  }

  void clearBit_statReg (int bit) {
    this.fdcStatusReg = this.clearBit(this.fdcStatusReg, bit);
  }

  // ---------------------------------------------------------------------------------
  // Read the Main Status Register 0xFB7E (FDC to Z80)
  int readStatus () { // 0xFB7E(RD)
    dbglog.logln("FDC read main stat reg: 0x" + hex(this.fdcStatusReg, 2));
    return this.fdcStatusReg;
  }

  // Write Motor Control Register: 0xFA7E (Z80 to FDC)
  void writeMotorCtrl(int dta) { // 0xFA7E & FA7F (WR)
    // tout ou rien : soit on allume tous les moteurs soit on les eteints tous
    dbglog.logln("FDC Motor: 0x" + hex(dta, 2));
    this.motorOn = dta & 0x01;
    this.motorToggled = true;
    this.motorCount = 500;
  }

  // Maybe not needed as there is no flag for Motor ready;
  void motorSpin () {
    if (this.motorToggled) {
      this.motorCount--;
      if (this.motorCount < 0) {
        this.motorToggled = false;
        this.motorReady = this.motorOn;
      }
    }
  }

  // ---------------------------------------------------------------------------------
  // Read Data from the data port (0xFB7F) (FDC to Z80)
  int readData () { // 0xFB7F (RD)
    int dta = this.readStateMachine();
    dbglog.logln("FDC Data Read: 0x" + hex(dta, 2));
    return dta;
  }

  // write Data on the port 0xFB7F (Z80 to FDC)
  void writeData (int dta) { // 0xFB7F (WR)
    dbglog.logln("FDC Data Write: 0x" + hex(dta, 2));
    this.writeStateMachine(dta);
  }

  // ___________________________________________________________
  // Write     : 0xFA7E(/7F) : FDD motor control
  // Read      : 0xFB7E      : FDC Main Status Register
  // Read/Write: 0xFB7F      : Data Register (alse 7E in Write)

  // ---------------------------------------------------------
  // PRIMARY STATUS REG : this.fdcStatusReg
  // b7 : Data Register Ready to send or receive data (Data Port Waiting) : 1 si Port de données pret et en attente
  // b6 : data Direction : 1 : FDC attend que le Z80 lise les data; 0: FDC attend les data venant du Z80
  // b5 : phase Stat : 1: Phase d'execution commencée; 0: Phase de résultat commencée
  // b4 : state :  1: read or write Instruction en cours; 0: FDC "pret" et peut recevoir une autre commande
  // b[3:0]: drives On/Off :  si un bit à '1', le lecteur correspondant au bit est en train de déplacer sa tête de lecture/écriture
  // ---------------------------------------------------------
  // SECONDARY STAT REGs : this.secondaryStatusRegs[n] ; n 0 to 6
  // ST0 :  ex: 0x20 instrution achevée ou 0x00 instruction encours
  // b[7:6] : b'11 : Disquette éjectée en cours d'opération, b'10 : Instruction inconnue; b'0x : instruction achévée avec Succès
  // b[5] : 1 = instruction "SEEK" achévée
  // b[4] : 1 : erreur mécanique ou échec du recalibrage
  // b[3] : lecteur ou tête indisponible
  // b[2,1:0] : tete en cours et n° lecteur en cours, c'est à dire lecteur ID
  //
  // ST1 : 0x00
  // b[7] : 1 : secteur de fin d'accès n'existe pas
  // b[6] : unused (0)
  // b[5] : erreur de checksum dans un secteur
  // b[4] : 1: Z80 a trop attendu
  // b[3] : unused (0)
  // b[2] : 1 si secteur de début d'accès n'existe pas ou ID secteur illisible
  // b[1] : 1 : tentative d'écriture ou de formatage sur disquette protégée
  // b[0] : erreur de formatage sur le disque
  //
  // ST2 :
  // b7 : unused (0)
  // b6 : 1 = secteur effacé a été rencontré
  // b5 : erreur de checksum dans données du secteur
  // b4 : n° de piste dans l'ID secteur ne correspond pas à la piste en cours
  // b3,2: voir "Scan" (Equal hit et Scan not satisfied
  // b1 : n° de piste de l'ID = &FF
  // b0 : erreur de formatage sur une zone de données
  //
  // ST3: 0x20 ou 0x30
  // b7 : lecteur en panne
  // b6 : Disquette protégée
  // b5 : tout est OK, lecteur prêt (ready signal)
  // b4 : tete en piste 0
  // b3 : 1= lecteur simple tete, 0: lecteur double tete
  // b2,1:0 : lecteur ID (n° tete et n° lecteur)
  int fdcInt = 0;
  int nbParams = 0;
  int nbReturn = 0;
  int realStart;
  int discOn;
  int trackStart;
  int[] paramData = new int[8];
  int resultPointer = 0;
  int dataPointer = 0;

  boolean inInstruction = false;
  boolean mtCommand = false;
  boolean skCommand = false;
  boolean gotAllParams = false;
  boolean execute = false;
  boolean resultToSend = false;

  // ---------------------------------------------------------------------------------
  void fdcInterrupt() {
    this.secondaryStatusRegs[0] = 0x20;
    this.fdcInt = 1;
  }

  // ---------------------------------------------------------------------------------
  void fdcInterruptError() {
    this.secondaryStatusRegs[0] = 0x80;
    this.fdcInt = 1;
  }

  // ---------------------------------------------------------------------------------
  void fdcInterruptClear() {
    this.secondaryStatusRegs[0] = 0x00;
    this.fdcInt = 0;
  }

  // ---------------------------------------------------------------------------------
  String getCommandName (int val) {
    switch (val) {
    case INSTR_LECTURETRK : 
      return NAME_LECTURETRK; // 0x02
    case INSTR_SPECIFYTRKDELAY : 
      return NAME_SPECIFYTRKDELAY; // 0x03
    case INSTR_QUERYSTATE : 
      return NAME_QUERYSTATE; // 0x04
    case INSTR_ECRITURESEC : 
      return NAME_ECRITURESEC; // 0x05
    case INSTR_LECTURESEC : 
      return NAME_LECTURESEC; // 0x06
    case INSTR_RECALIBRAGE : 
      return NAME_RECALIBRAGE; // 0x07
    case INSTR_INTSTATUS : 
      return NAME_INTSTATUS; // 0x08
    case INSTR_ECRITURESECEFF : 
      return NAME_ECRITURESECEFF; // 0x09
    case INSTR_IDSECTSUIV : 
      return NAME_IDSECTSUIV; // 0x0A
    case INSTR_LECTURESECEFF : 
      return NAME_LECTURESECEFF; // 0x0C
    case INSTR_FORMAT : 
      return NAME_FORMAT; // 0x0D
    case INSTR_SEEKTRACK : 
      return NAME_SEEKTRACK; // 0x0F
    case INSTR_VERSION : 
      return NAME_VERSION; // 0x10 
    case INSTR_SCANEQUAL : 
      return NAME_SCANEQUAL; // 0x11
    case INSTR_SCALOWORNEQUAL : 
      return NAME_SCALOWORNEQUAL; // 0x19
    case INSTR_SCAHIGHORNEQUAL : 
      return NAME_SCAHIGHORNEQUAL; // 0x1D
    default: 
      return "Unknown Command";
    }
  }

  // ---------------------------------------------------------------------------------
  void getCommand (int val) {
    this.mtCommand = (val & 0x80) > 0; // b7 : multitrack
    this.skCommand = (val & 0x20) > 0; // b5 : skip deleted
    this.command = val & 0x1F;
    this.cmdName = this.getCommandName(this.command);

    dbglog.logln("=========================================================== Command = 0x" + hex(this.command, 2) + ": " + this.cmdName);
    this.inInstruction = true;
    this.gotAllParams = false;
    this.execute = true;

    this.resultPointer = 0;
    this.dataPointer = 0;

    this.fdcStatusReg = 0x00 ; // set to 0x90 below
    this.setBit_statReg(STATREG_DATAPORTWAITING); // set bit 7 : data port ready and...
    this.clearBit_statReg(STATREG_FDCWAITINGFORZ80READ); // clear bit 6 : data sent from Z80 to FDC
    this.clearBit_statReg(STATREG_PHASEINSTRUCTION); // clear bit 5 : b5 is only set during the execution phase
    this.setBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4 set so no other command could be sent
    switch (this.command) {

    case INSTR_LECTURETRK : // 0x02 : read diag / read track
    case INSTR_ECRITURESEC : // 0x05 : write sector
    case INSTR_LECTURESEC : // 0x06 : read sector
    case INSTR_ECRITURESECEFF : // 0x09 : write delected sector
    case INSTR_LECTURESECEFF : // 0x0C : read deleted sector
    case INSTR_SCANEQUAL : // 0x11 : not yet supported
    case INSTR_SCALOWORNEQUAL : // 0x19 : not yet supported
    case INSTR_SCAHIGHORNEQUAL : // 0x1D : not yet supported
      this.nbParams = PARAM_REGULAR; // 8 : Drive ID, sector info C, H, R, N, EOT, GPL, DTL
      this.nbReturn = RET_REGULAR; // 7 : ST0 to 2, C, H, R, N
      this.secondaryStatusRegs[0] = 0x80;
      break;

    case INSTR_SPECIFYTRKDELAY : // 0x03 : specify
      this.nbParams = PARAM_SPECIFYTRKDELAY; // 2: SRT+HUT et HLT+ND
      this.execute = false;
      this.nbReturn = RET_NONE; // none
      break;

    case INSTR_QUERYSTATE : // 4; drive status / sense drive
      this.nbParams = PARAM_QUERYSTATE; // 1: Lecteur ID
      this.execute = false;
      this.nbReturn = RET_QUERYSTATE; // 1: ST3
      this.secondaryStatusRegs[3] = this.driveId | 0x28;
      if (this.discTrack == 0) {
        this.secondaryStatusRegs[3] |= 0x10;
      }
      break;

    case INSTR_RECALIBRAGE : // 0x07 : recalibrate
      this.nbParams = PARAM_RECALIBRAGE; // 1: ID lecteur
      this.execute = false; // in fact "execute = true", but the execution is done in getParam() instead
      this.nbReturn = RET_NONE; // none
      this.fdcInterrupt();
      // this.secondaryStatusRegs[0] = 0x00; // b5 = 0
      break;

    case INSTR_INTSTATUS : // 0x08 : sense the interrupt state
      this.nbParams = PARAM_NONE; // none
      this.execute = false;
      this.nbReturn = RET_INTSTATUS; // 2: ST0; PCN = n°PisteEnCours
      this.setBit_statReg(STATREG_FDCWAITINGFORZ80READ); // 0xD0
      break;

    case INSTR_IDSECTSUIV : // 0x0A : read id
      this.nbParams = PARAM_IDSECTSUIV; // 1: Drive Id
      this.execute = false;
      this.nbReturn = RET_REGULAR; // 7
      break;

    case INSTR_FORMAT : // 0x0D : format (write)
      this.nbParams = PARAM_FORMAT; // 5
      this.nbReturn = RET_REGULAR; // 7
      break;

    case INSTR_SEEKTRACK : //  0x0F : seek track
      this.nbParams = PARAM_SEEKTRACK; // 2: Lecteur ID et NCN (n°Piste)
      this.nbReturn = RET_SEEKTRACK; // none
      this.execute = false; // in fact "execute = true", but the execution is done in getParam() instead
      this.fdcInterrupt();
      this.secondaryStatusRegs[0] |= (1 << (this.driveId & 0x03));
      break;

    case INSTR_VERSION : //  10
      this.nbParams = PARAM_NONE; // none
      this.execute = false;
      this.setBit_statReg(STATREG_FDCWAITINGFORZ80READ); // set bit 6 : Z80 will now be reading
      this.nbReturn = RET_VERSION; // ST0 = 0x80 for 765A
      break;

    default: // INVALID
      this.nbParams = 0; // none
      this.fdcStatusReg = 0x81;
      this.execute = false;
      this.nbReturn = 1; // ST0 = 0x80 for 765A
    }
    this.gotAllParams = (this.nbParams > 0) ? false : true;
    this.resultToSend = (this.nbReturn > 0) ? true : false;
  }

  int srt = 0xE;
  int hut, hlt, nd;
  int eot, gpl, dtl, filler;
  int sectorH = 0; // tête 0 ou 1; sur CPC toujours 0
  int sectorR = 0xC1; // n° du secteur en cours
  int sectorN = 2; // taille du secteur; tjs 2 sur cpc
  int sectorSizeType, sectorPerTrack;

  // ---------------------------------------------------------------------------------
  // cmd 4a msr 90 param 0 got all param ; msr f0 (exp 50)
  // data c2 msr f0 msr f0
  // res 20 msr d0 d0; 0 0 0 0 c1 2

  void getParam (int val) {
    if (this.nbParams > 0) {
      this.setBit_statReg(STATREG_DATAPORTWAITING); // 0x90 : set bit 7
      this.clearBit_statReg(STATREG_FDCWAITINGFORZ80READ); // bit 6 : 0 = Z80 Write to FDC
      this.clearBit_statReg(STATREG_PHASEINSTRUCTION); // bit 5
      this.paramData[this.nbParams - 1] = val; // paramData[0] is the last param received
      this.nbParams--;
      dbglog.logln("Param = 0x" + hex(val, 2));
    }
    if (this.nbParams == 0) {
      dbglog.logln("Got all params");
      this.gotAllParams = true;
      //  this.clearBit_statReg(STATREG_DATAPORTWAITING); // 0x07 : clear bit 7 : data port not ready (FDC munching parameters)...
      this.setBit_statReg(STATREG_FDCWAITINGFORZ80READ); // bit 6 : 1 : FDC and Z80 in sync!
      this.setBit_statReg(STATREG_PHASEINSTRUCTION); // bit 5
      this.setBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4 set so no other command could be sent

      switch (this.command) {
      case INSTR_LECTURETRK : // 2 : read diag
      case INSTR_ECRITURESEC : // 5; write sector
      case INSTR_LECTURESEC : // 6; read sector
        // case INSTR_ECRITURESECEFF : // 9; write delected sector
        // case INSTR_LECTURESECEFF : // C: read deleted sector
        // case INSTR_SCANEQUAL : // not yet supported
        // case INSTR_SCALOWORNEQUAL : // not yet supported
        // case INSTR_SCAHIGHORNEQUAL : // not yet supported
        this.driveId = this.paramData[7]; // Drive Id
        this.discTrack = this.paramData[6]; // n° de piste (0 to 41)
        this.sectorH = this.paramData[5]; // n° de tête (0 or 1)
        this.sectorR = this.paramData[4]; // n° du secteur (De &C1 à &C9 pour DATA ou  &41 à &49 pour CPM)
        this.sectorN = this.paramData[3]; // Taille du secteur (in bytes or type (2)???); probably the latter as 512 doesn't fit in a 8b reg!
        this.eot = this.paramData[2]; // end of track
        this.gpl = this.paramData[1];
        this.dtl = this.paramData[0];
        this.sectorStart = this.sectorR;
        this.sectorEnd = this.eot;
        this.fdcInterrupt();
        break;

      case INSTR_SPECIFYTRKDELAY : // 3
        this.srt = (this.paramData[1] & 0xF0) >> 4; // step rate in ms (0xF = 1ms, 0xE = 2ms, etc)
        this.hut = (this.paramData[1] & 0x0F); //Head unload time
        this.hlt = (this.paramData[0] & 0xFE) >> 1; // Head load time
        this.nd  = (this.paramData[0] & 0x01); // Non-DMA mode (should be 1 on CPC)
        break;

      case INSTR_QUERYSTATE : // 4; drive status
      case INSTR_IDSECTSUIV : // A : read id
        this.driveId = this.paramData[0];
        break;

      case INSTR_RECALIBRAGE : // 7; recalibrate
        this.driveId = this.paramData[0];
        this.discTrack = this.discTrack - 77; // recal move back the head a maximum of 77 tracks unless it reached track 0 in which case it stays at 0
        this.discTrack = (this.discTrack < 0) ? 0 : this.discTrack;
        break;

      case INSTR_FORMAT : // D ; format (write)
        this.driveId = this.paramData[4];
        this.sectorSizeType = this.paramData[3]; // should be 2
        this.sectorPerTrack = this.paramData[2]; // should be 9
        this.gpl = this.paramData[1]; // gap3
        this.filler = this.paramData[0];
        break;

      case INSTR_SEEKTRACK : //  F
        this.driveId = this.paramData[1];
        this.discTrack = this.paramData[0]; // desired cylinder number
        this.fdcInterrupt();
        break;

      default:
        //
      }
    }
  }

  // ---------------------------------------------------------------------------------
  void writeStateMachine (int val) {
    val &= 0xFF;
    // nouvelle instruction détectée, décodons la (et obtenons le nb de param):
    if (!this.inInstruction) {
      dbglog.logln("*** WZ *********  track: " + this.discTrack + " ; Sector: 0x" + hex(this.sectorStart, 2) + " ; pos " + this.dataPointer + " ; val = 0x" + hex(val, 2));
      this.getCommand(val);

      // sinon on est dans une instruction; on lit tous les parametres un à un
    } else {
      if (!this.gotAllParams) {
        dbglog.logln("*** WZ *********  track: " + this.discTrack + " ; Sector: 0x" + hex(this.sectorStart, 2) + " ; pos " + this.dataPointer + " ; val = 0x" + hex(val, 2));
        this.getParam(val);
      } else { // if (this.execute) {
        dbglog.logln("*** WD *********  track: " + this.discTrack + " ; Sector: 0x" + hex(this.sectorStart, 2) + " ; pos " + this.dataPointer + " ; val = 0x" + hex(val, 2));
        this.getDataFromZ80(val); // Z80 Writing to FDC
      }
    }
    this.isInstrComplete();
    dbglog.logFlush();
  }

  // ---------------------------------------------------------------------------------
  int readStateMachine () {
    int val;
    if (this.execute) {
      val = this.sendDataToZ80(); // Z80 reading from FDC
      dbglog.logln("*** RD *********  track: " + this.discTrack + " ; Sector: 0x" + hex(this.sectorStart, 2) + " ; pos " + this.dataPointer + " ; val = 0x" + hex(val, 2));
    } else { // if (this.resultToSend) {
      val = this.sendResultToZ80();
      dbglog.logln("*** RZ *********  track: " + this.discTrack + " ; Sector: 0x" + hex(this.sectorStart, 2) + " ; pos " + this.dataPointer + " ; val = 0x" + hex(val, 2));
    }
    this.isInstrComplete();
    dbglog.logFlush();
    return val;
  }

  // ---------------------------------------------------------------------------------
  boolean isInstrComplete () {
    boolean ret = 
      (this.inInstruction && 
      ((this.nbParams == 0) || this.gotAllParams) && 
      !this.execute && 
      !this.resultToSend );
    String dbg = 
      "in instr:" + this.inInstruction + ", " + 
      "nbparam=0? " + (this.nbParams == 0) + ", " + 
      "gotallparam:"+this.gotAllParams + ", " + 
      "exec:"+this.execute + ", " + 
      "nbret=0? " + (this.nbReturn == 0)  + ", " + 
      "restosend: " + this.resultToSend;

    if (ret) {
      this.inInstruction = false;
      this.setBit_statReg(STATREG_DATAPORTWAITING); // 0x80 : set bit 7 : data port ready
      this.clearBit_statReg(STATREG_FDCWAITINGFORZ80READ); // clear bit 6 : data sent from Z80 to FDC
      this.clearBit_statReg(STATREG_PHASEINSTRUCTION); // clear bit 5 : not executing
      this.clearBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4 clear : can accept new commands
      this.secondaryStatusRegs[0] = 0x20;
      dbglog.logln("Command completed : " + dbg);
    }
    return ret;
  }

  // ---------------------------------------------------------------------------------
  void getDataFromZ80 (int val) {
    this.setBit_statReg(STATREG_DATAPORTWAITING); // 0xB0 : set bit 7
    this.clearBit_statReg(STATREG_FDCWAITINGFORZ80READ); // bit 6 reset : Z80 Writing
    this.setBit_statReg(STATREG_PHASEINSTRUCTION); // set bit 5 : Execution phase
    this.setBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4 clear : can accept new commands

    this.dataPointer++;

    switch (this.command) {
    case INSTR_ECRITURESEC : // 5; write sector
      // case INSTR_ECRITURESECEFF : // 9; write delected sector
      // Wrting to a floppy is not yet supported // data
      this.fdcInterrupt();
      break;

    case INSTR_FORMAT : // D ; format (write)
      // Wrting to a floppy is not yet supported // full track
      break;

    default:
      //
    }
  }

  // Convert Sector Id like "0xC1, 0xC9 or 0x42, etc..." to sector number like "0, 8 or 1, etc...."
  int convSectId2Num (int sid) {
    return ((sid & 0x0F) - 1);
  }

  int wrapIncrSect (int sect) {
    int msk = sect & 0xC0;
    int t = (sect + 1) & 0x3F;
    return (msk | ((t >= SECTORMAX) ? 1 : t));
  }

  // ---------------------------------------------------------------------------------
  int sendDataToZ80 () {
    int databyte;
    int sectorNum, secEndNum;

    this.setBit_statReg(STATREG_DATAPORTWAITING); // 0x70 : set bit 7
    this.setBit_statReg(STATREG_FDCWAITINGFORZ80READ); // bit 6 set : Z80 Reading
    this.setBit_statReg(STATREG_PHASEINSTRUCTION); // set bit 5 : Execution phase
    this.setBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4 clear : can accept new commands

    switch (this.command) {
    case INSTR_LECTURESEC : // 6; read sector
      // case INSTR_LECTURESECEFF : // C: read deleted sector
      // fetch next byte
      sectorNum = this.convSectId2Num(this.sectorStart);
      secEndNum = this.convSectId2Num(this.sectorEnd);
      dbglog.logln("Reading track : " + this.discTrack + ", sector : 0x" + hex(this.sectorStart, 2) + " (#" + sectorNum + ") , data byte pos : " + this.dataPointer);
      databyte = this.discData[this.discTrack][sectorNum][this.dataPointer]; // sectorStart C1 to C9, but for the field we need 0 to 8
      dbglog.logln("Reading : 0x" + hex(databyte, 2) + " at dataPointer = " + this.dataPointer);
      this.dataPointer++;
      // si dernier byte du secteur
      if (this.dataPointer == SIZEMAX) {
        // si dernier secteur alors fin de lecture
        if (sectorNum == secEndNum) {
          this.fdcInterruptError();
          this.discOn = 0;
          this.execute = false;
          // sinon change de secteur et continue
        } else {
          this.dataPointer = 0;
          this.sectorStart++;
          sectorNum = this.convSectId2Num(this.sectorStart);
          if (sectorNum == SECTORMAX) { //(this.discTracks[this.discTrack] + 1)) {
            if (this.mtCommand) { // MultiTrack
              this.discTrack++;
              if (this.discTrack == TRACKMAX) {
                this.execute = false;
                this.fdcInterrupt();
                this.discOn = 0;
              }
            }
            this.sectorStart = this.wrapIncrSect(this.sectorStart & 0xC0); // reinit sector to 0xC1 (AmsDos) or 0x41 (CP/M)
            sectorNum = this.convSectId2Num(this.sectorStart);
          }
          /*      this.realStart = 0;
           for (int sect = 0; sect < SECTORMAX; sect++) {
           if ((this.sectorInfo[this.trackStart][sect][2] & 0x0F) == sectorNum) {
           this.realStart = sect;
           break;
           }
           }
           */
        }
      }
      //this.fdcInterrupt();
      return databyte;
      //break;

      //   case INSTR_LECTURETRK : // 2 : read diag
      //     //all data from index hole to EOT (end of track)
      //     break;

      /* case INSTR_IDSECTSUIV : // A : read id
       this.execute = false;
       this.setBit_statReg(STATREG_DATAPORTWAITING); // 0xF0 : set bit 7
       this.setBit_statReg(STATREG_FDCWAITINGFORZ80READ); // bit 6 set : Z80 Reading
       this.setBit_statReg(STATREG_PHASEINSTRUCTION); // bit 5
       this.setBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4
       return this.wrapIncrSect(this.sectorStart);
       // break;
       */

    default:
      return 0x5E; //ERR!
      //
    }
  }

  // ---------------------------------------------------------------------------------
  int sendResultToZ80 () {
    int val;
    this.setBit_statReg(STATREG_DATAPORTWAITING); // 0xD0 : set bit 7
    this.setBit_statReg(STATREG_FDCWAITINGFORZ80READ); // bit 6 set : Z80 Reading
    this.clearBit_statReg(STATREG_PHASEINSTRUCTION); // clear bit 5 : Execution phase finished
    this.setBit_statReg(STATREG_INSTRUCTIONENCOURS); // bit 4 clear : can accept new commands
    if (this.resultPointer == 0) {
      this.fdcInterrupt();
    }
    this.dataPointer = 0;
    this.resultPointer++;
    dbglog.logln("Send result");
    switch (this.command) {
    case INSTR_LECTURESEC : // 6; read sector
      // case INSTR_LECTURESECEFF : // C: read deleted sector
    case INSTR_ECRITURESEC : // 5; write sector
      // case INSTR_ECRITURESECEFF : // 9; write delected sector
    case INSTR_LECTURETRK : // 2 : read diag
    case INSTR_FORMAT : // D ; format (write)
      // case INSTR_SCANEQUAL : // not yet supported
      // case INSTR_SCALOWORNEQUAL : // not yet supported
      // case INSTR_SCAHIGHORNEQUAL : // not yet supported
      // ST0, ST1, ST2, SectorC, H, R, N
      switch (this.resultPointer) {
      case 1 :
        this.secondaryStatusRegs[0] = 0x20 + this.driveId;
        val = this.secondaryStatusRegs[0];
        break;
      case 2 :
        this.secondaryStatusRegs[1] = 0x00;
        val = this.secondaryStatusRegs[1];
        break;
      case 3 :
        this.secondaryStatusRegs[2] = 0x00;
        val = this.secondaryStatusRegs[2];
        break;
      case 4 :
        val = this.discTrack; // sector C (current track nb)
        break;
      case 5 :
        val = this.head; // sector H : 0x00
        break;
      case 6 :
        val = this.sectorStart; // sector R : n° du secteur sous sa forme 0xC1 to 0xC9
        break;
      default: // 7
        val = 0x02; // sector N : taille
      }
      break;

    case INSTR_IDSECTSUIV : // A : read id
      switch (this.resultPointer) {
      case 1 :
        val = this.secondaryStatusRegs[0];
        break;
      case 2 :
        val = this.secondaryStatusRegs[1];
        break;
      case 3 :
        val = this.secondaryStatusRegs[2];
        break;
      case 4 :
        val = this.discTrack; // sector C (current track nb)
        break;
      case 5 :
        val = this.sectorH; // sector H : 0x00
        break;
      case 6 :
        this.sectorR = this.wrapIncrSect(this.sectorStart);
        val = this.sectorR; // next sector R : n° du secteur sous sa forme 0xC1 to 0xC9
        break;
      default:
        this.fdcStatusReg = 0x80;
        val = this.sectorN; // sector N : taille
      }
      break;

    case INSTR_INTSTATUS : // 8; sense the interrupt state
      // ST0, PCN (current track n°)
      if (this.resultPointer == 1) { // param #1
        int ssr0 = this.secondaryStatusRegs[0];
        this.fdcInterruptClear();
        val = ssr0;
      } else { // param #2
        this.fdcStatusReg = 0x80;
        val = this.discTrack;
      }
      break;

    case INSTR_QUERYSTATE : // 4; drive status
      // ST3
      val = this.secondaryStatusRegs[3];
      break;

    default: // INVALID
      // case INSTR_VERSION : // 10; drive status
      //   // ST0 : 0x80
      //   break;
      // ST0
      val = this.secondaryStatusRegs[0];
    }
    if (this.resultPointer >= this.nbReturn) {
      this.resultToSend = false;
      dbglog.logln("Got " + this.resultPointer + " result(s)");
      this.resultPointer = 0;
    }
    return val;
  }


  // ---------------------------------------------------------------------------------
  void readFloppy (String fname) {
    println("Inserting Diskette : " +fname);
    this.diskette = new D7();
    this.discData = this.diskette.readFile(fname);
  }
}