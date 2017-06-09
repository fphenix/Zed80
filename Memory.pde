class Memory {
  RAM[] ram;
  ROM[] uproms;
  ROM lorom;
  Firmware fwv; // ref

  PrintWriter memdmp;
  PrintWriter romdmp;

  // on 6128: 8 blocks of 16KB, with only 4 available at a time
  //     A B C D  : A : 0x0000 to 0x3FFFF, B : from 0x4000, C : from 0x8000, D : from 0xc000 to &FFFF
  // 0 : 0 1 2 3
  // 1 : 0 1 2 7
  // 2 : 4 5 6 7
  // 3 : 0 3 2 7
  // 4 : 0 4 2 3
  // 5 : 0 5 2 3
  // 6 : 0 6 2 3
  // 7 : 0 7 2 3
  int addr;
  int datum; // byte of data

  int[] selRAMBank = {0, 1, 2, 3};
  int[] selRAMPage = {0, 0, 0, 0};

  boolean lowerROMpaging;
  boolean upperROMpaging;
  int upperROMsel = 0;
  String whichMemName;

  // CPC464 : Firmware v1 (english) , f1 (french) -- Basic v1.0 -- AmsDOS None!
  // CPC664 : Firmware v2 (english) , f2 (french) -- Basic v1.1 -- AmsDOS v0.5
  // CPC6128 : Firmware v3 (english) , f3 (french) -- Basic v1.2x -- AmsDOS v0.5

  Memory () {
    this.ram = new RAM[2]; // could be 8 with extended memory (external banks)
    this.ram[0] = new RAM(); // page 0 : 64KB base RAM
    this.ram[1] = new RAM(); // page 1 : CPC6128 extra 64KB
    this.lorom = new ROM("Lower", "FirmwareF3.rom"); // F3 = CPC6128-français
    this.uproms = new ROM[16];
    for (int i = 0; i < 16; i++) {
      if ((i == 0) || (i == 7)) {
        continue;
      }
      this.uproms[0] = new ROM("Upper" + i, null);
    }
    this.uproms[0] = new ROM("Upper0", "BasicFR.rom");
    this.uproms[7] = new ROM("Upper7", "Amsdos.rom"); // d7 dos 6128 or 464 with DDI (external d7)
    this.memdmp = null;
    this.lowerROMpaging = false;
    this.upperROMpaging = false;
    this.whichMemName = "";
  }

  void setRef (Firmware fwvref) {
    this.fwv = fwvref;
  }

  // 0x0000 to 0x3FFF : 0
  // 0x4000 to 0x7FFF : 1
  // 0x8000 to 0xBFFF : 2
  // 0xC000 to 0xFFFF : 3
  int addrIsInBank (int addr) {
    return ((addr >> 14) & 0x03);
  }

  boolean isInRange(int a, int low, int high) {
    if (low > high) {
      return isInRange(a, high, low);
    } else {
      return ((a >= low) && (a <= high));
    }
  }

  // recalc the address of the data based on selected RAM config
  int recalcAddr(int a, int bank) {
    return ((a & 0x3FFF) | ((bank & 0x03) << 14));
  }

  // peek (read) can be done in rom or ram depending on the page select
  int peek (int a) {
    this.addr = a & 0xFFFF;
    // if ROM paging selected for UpperROM, then read from the chosen Page (upperROMsel)
    if (this.isInRange(a, 0xC000, 0xFFFF) && this.upperROMpaging) {
      this.whichMemName = "UROM" + hex(this.upperROMsel, 1);      
      if ((this.upperROMsel != 0) && (this.upperROMsel != 7)) {
        return 0x00;
      }
      return (this.uproms[this.upperROMsel].data[this.addr & 0x3FFF] & 0xFF);
      // if ROM paging selected for LowerROM, then read from it
    } else if (this.isInRange(a, 0x0000, 0x3FFF) && this.lowerROMpaging) {
      this.whichMemName = "LROM0";
      return (this.lorom.data[this.addr & 0x3FFF] & 0xFF);
      // in any other case read the RAM
    } else {
      return this.rampeek(a);
    }
  }

  // peek in ram
  int rampeek (int a) {
    a &= 0xFFFF;
    int bnk = this.addrIsInBank(a);
    int pointedBnk = this.selRAMBank[bnk];
    int pg = this.selRAMPage[bnk];
    int adr = this.recalcAddr(a, pointedBnk);
    this.whichMemName = "RDR" + pg + "" + pointedBnk;
    return (this.ram[pg].data[adr] & 0xFF);
  }

  // The Gate Array (and DMA, ...) can only read fron the base 64K RAM whatever MMR config may be set
  int basepeek (int adr) {
    this.whichMemName = "BRAM" + ((adr & 0xC000) >> 14);
    return (this.ram[0].data[adr] & 0xFF);
  }

  // can only poke (write) in RAM
  void poke (int tadr, int val) {
    this.addr = tadr & 0xFFFF;
    int bnk = this.addrIsInBank(this.addr);
    int pointedBnk = this.selRAMBank[bnk];
    int pg = this.selRAMPage[bnk];
    int adr = this.recalcAddr(this.addr, pointedBnk);
    this.whichMemName = "WRR" + pg + "" + pointedBnk;
    this.ram[pg].data[adr] = val & 0xFF;
  }

  // poke the given list of byte data into memory from addr (incrementing).
  void pokeList (int addr, String data) {
    String[] bytesStr = split(data.trim(), ' ');
    int currbyte;
    int a = addr;
    for (int i = 0; i < bytesStr.length; i++) {
      currbyte = int(unhex(bytesStr[i]));
      this.poke(a, currbyte);
      a++;
    }
  }

  void bootUpMem () {
    this.lowerROMpaging = true;
    this.upperROMpaging = false;
    this.upperROMsel = 0;
  }

  // copy RST zone from ROM to RAM
  void copyROMZone () {
    for (int i = 0; i < 0x40; i++) {
      this.poke(i, this.rompeek(0, 0, i));
    }
    for (int i = 0; i < 0x01E4; i++) {
      this.poke(0xB900+i, this.rompeek(0, 0, 0x03A6+i));
    }
  }

  void memDump () {
    this.memdmp = createWriter("data/Logs/MemDump.txt"); // Create a new file in the sketch directory
    int val8;
    String asciistr = "";
    for (int a = 0; a < 0x10000; a++) {
      if (a % 16 == 0) {
        this.memdmp.print(hex(a, 4) + " : ");
      }
      val8 = this.rampeek(a);
      if ((val8 >= 32) && (val8 < 127)) {
        asciistr += char(val8);
      } else {
        asciistr += "~";
      }
      this.memdmp.print(hex(val8, 2) + " ");
      if ((a + 1) % 16 == 0) {
        this.memdmp.println(": " + asciistr);
        asciistr = "";
      }
    }
    this.memdmp.flush(); // Writes the remaining data to the file
    this.memdmp.close(); // Finishes the file
  }

  // peek can be done in rom or ram
  int rompeek (int bank, int page, int a) {
    this.addr = a & 0x3FFF;
    if (bank == 0) {
      this.whichMemName = "LROM0";
      return (this.lorom.data[this.addr] & 0xFF);
    } else {
      this.whichMemName = "UROM" + page;
      return (this.uproms[page].data[this.addr] & 0xFF);
    }
  }

  // 
  String getRomId (int bank, int page) {
    if (bank == 0) {
      return this.lorom.id;
    } else {
      return this.uproms[page].id;
    }
  }

  void romDumpRom (int tmpbank, int tmppage) {
    int val8;  
    this.romdmp.println("  **  ROM : " + this.getRomId(tmpbank, tmppage));
    for (int a = 0; a < 0x04000; a++) {
      if (a % 16 == 0) {
        this.romdmp.print(hex(a, 4) + " : ");
      }
      val8 = this.rompeek(tmpbank, tmppage, a);
      this.romdmp.print(hex(val8, 2) + " ");
      if ((a + 1) % 16 == 0) {
        this.romdmp.println("");
      }
    }
  }

  void romDump () {
    this.romdmp = createWriter("data/Logs/RomDump.txt"); // Create a new file in the sketch directory
    this.romDumpRom(0, 0);
    this.romDumpRom(3, 0);
    this.romDumpRom(3, 7);
    this.romdmp.flush(); // Writes the remaining data to the file
    this.romdmp.close(); // Finishes the file
  }

  /*;This register exists only in CPCs with 128K RAM (like the CPC 6128, 
   ;or CPCs with Standard Memory Expansions). 
   ;Note: In the CPC 6128, the register is a separate PAL that assists 
   ;the Gate Array chip.
   ;The 3bit RAM Config value is used to access the total of 128K RAM 
   ;(RAM Banks 0-7) that is built into the CPC 6128. Normally the register 
   ;is set to 0, so that only the first 64K RAM are used (identical to the
   ;CPC 464 and 664 models). The register can be used to select between the 
   ;following eight predefined configurations only:
   // conf : banks
   // 0 : 0 1 2 3  ** DEFAULT; 464 Mode and 6128 default
   // 1 : 0 1 2 7
   // 2 : 4 5 6 7
   // 3 : 0 3 2 7
   // 4 : 0 4 2 3
   // 5 : 0 5 2 3
   // 6 : 0 6 2 3
   // 7 : 0 7 2 3
   // Note: CRTC only displays from primary RAM
   // Memory range (64 kB blocks of RAM selected, divided in 4 sub-blocks of 16KB): 
   // 0x0000 to 0x3FFF
   // 0x4000 to 0x7FFF
   // 0x8000 to 0xBFFF
   // 0xC000 to 0xFFFF
   // blocks 0 to 3 : within the primary selected RAM block
   // blocks 4 to 7 : within the secondary selected RAM block
   //------------------------------------------------------
   // 1 page = 64KB = 4 banks of 16KB
   // page 0 : banks 0 1 2 3 : base 64KB
   // page 1 : banks 4 5 6 7 : extra 64KB on 6128
   // page n : banks 4n +1 + 1 +1 , up to 8 for extended memory (external)
   //------------------------------------
   // b[7:6] = 11 (MMR register)
   // S = 0:
   //  * mm = 0 : 0 1 2 3     : Default config 
   //  * mm = 1 : 0 1 2 page-bank3 (ex: for page = 1, then 7)
   //  * mm = 2 : p0 p1 p2 p3  (ex for page = 1: 4 5 6 7)
   //  * mm = 3 : 0 3 2 p3 (ex for page 1: 7)
   // S = 1
   //  * mm = bank ; 0 pb 2 3  (ex for bank 2, page 1 : pb=6
   */
  void selExtRAMConfig (int page, int s, int mm) {
    for (int i = 0; i < 4; i++) {
      this.selRAMBank[i] = i;
      this.selRAMPage[i] = 0;
    }
    if (s == 0) {
      switch (mm) {
      case 1 : 
        this.selRAMPage[3] = page;
        break;
      case 2 : 
        for (int i = 0; i < 4; i++) {
          this.selRAMPage[i] = page;
        }
        break;
      case 3 :
        this.selRAMBank[1] = 3;
        this.selRAMPage[3] = page;
        break;
      default:
        // nothing to do!
      }
    } else {
      this.selRAMBank[1] = mm;
      this.selRAMPage[1] = page;
    }
  }

  void addr2zone (int a) {
    if ((a >= 0x0000) && (a <= 0x003F)) {
      log.logln("RESTART RST"); // RST 0 : init CPC; RST 0x38 : saut du mode IM1
    } else if ((a >= 0x0040) && (a <= 0x016F)) {
      log.logln("Tampon de convertion des saisies clavier en BASIC");
    } else if ((a >= 0x0170) && (a <= 0xA6FF)) {
      log.logln("Zone de travail du BASIC (programme, variables, etc.");
      if ((a >= 0x4000) && (a <= 0x7FFF)) {
        log.logln("Cette partie peux être paginée (6128 only) pour accéder à 64kB supplémentaire grace à une OUT &7F00, &C0 (normal, bank 1), ou &C4 à &C7 pour extended bank 0 à 3. Peut aussi être utilisée pour la video (voir vecteur BC08)");
      }
    } else if ((a >= 0xA700) && (a <= 0xABFF)) {
      log.logln("DOS si equipé de disquette, suite de la Zone de travail du BASIC (programme, variables, etc.");
    } else if ((a >= 0xAC00) && (a <= 0xB0FF)) {
      log.logln("Zone de travail du Basic BASIC");
      if ((a >= 0xAC8A) && (a <= 0xAD89)) {
        log.logln("Tampon saisie clavier (256 octets)");
      } else if ((a >= 0xAE8B) && (a <= 0xB08A)) {
        log.logln("pile Basic (512 octets, croissante)");
      }
    } else if ((a >= 0xB100) && (a <= 0xB8FF)) {
      log.logln("Paramètres système (écran, couleurs, touches, gestion des fenêtres, du lecteur de cassettes, etc... )");
    } else if ((a >= 0xB900) && (a <= 0xBDC0)) {
      log.logln("Vecteurs systèmes/Firmware");
    } else if ((a >= 0xBDC1) && (a <= 0xBDCC)) {
      log.logln("Vecteurs systèmes/Firmware (464 only)");
    } else if ((a >= 0xBDCD) && (a <= 0xBDF6)) {
      log.logln("Vecteurs de saut/indirection");
    } else if ((a >= 0xBDF7) && (a <= 0xBE3F)) {
      log.logln("Libre");
    } else if ((a >= 0xBE40) && (a <= 0xBE7F)) {
      log.logln("Zone de travail du système disque");
    } else if ((a >= 0xBE80) && (a <= 0xBFFF)) {
      log.logln("Pile système (décroissante à partir de 0xBFFF); Zone 0xBE80-0xBEFC parfois utilisée pour stoker des routines car rarement écrasée");
    } else if ((a >= 0xC000) && (a <= 0xFFFF)) {
      log.logln("Vidéo (note: certaines zones ne sont pas affichées et peuvent donc servir à stocker des petites routines...");
    } else {
      log.logln("Whatchew talkin bout? Shouldn't reach this...");
    }
  }

  void RETVectors () {
    for (int a = 0x0000; a <= 0xFFFF; a++) {
      if (this.fwv.isVector(a)) {
        this.poke(a, 0xC9);
      }
    }
  }

  void loadRam (String jsonfile, String filename) {
    JSONArray json;
    JSONObject currfile;
    boolean found = false;
    json = loadJSONArray("./data/JSON/" + jsonfile);
    for (int i = 0; i < json.size(); i++) {
      currfile = json.getJSONObject(i);

      String fname = currfile.getString("fname");

      if (!filename.equals(fname)) {
        continue;
      }

      found = true;
      //int id = currfile.getInt("id");
      int loadaddr = currfile.getInt("loadaddr");
      //int len = currfile.getInt("length");
      //int startaddr = currfile.getInt("startaddr");
      //int filetype = currfile.getInt("filetype");
      String data = currfile.getString("data");

      this.pokeList(loadaddr, data);

      log.logln("Done loading Test "  + fname + " @ 0x" + hex(loadaddr, 4 ) + " !");
      break;
    }
    if (!found) {
      println("File >" + filename + "< not found! while reading test file data");
    }
  }

  void testASM (String testname) {
    this.loadRam("testAsm.json", testname);
  }
}