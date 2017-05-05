class Memory {
  RAM ram;
  ROM[] uproms;
  ROM lorom;
  Firmware fwv; // ref

  PrintWriter memdmp;
  PrintWriter romdmp;

  int bank; // 0 to 3
  int page; // 0 to 7
  int addr;
  int datum; // byte of data

  boolean lowerROMpaging;
  boolean upperROMpaging;
  int upperROMsel = 0;

  Memory () {
    this.ram = new RAM();
    this.lorom = new ROM("Lower", "Firmware.rom");
    this.uproms = new ROM[8];
    this.uproms[0] = new ROM("Upper0", "Basic.rom");
    this.uproms[7] = new ROM("Upper7", "Amdos.rom");
    this.memdmp = null;
    this.lowerROMpaging = false;
    this.upperROMpaging = false;
  }

  void setRef (Firmware fwvref) {
    this.fwv = fwvref;
  }

  boolean isInRange(int a, int low, int high) {
    if (low > high) {
      return isInRange(a, high, low);
    } else {
      return ((a >= low) && (a <= high));
    }
  }

  // peek can be done in rom or ram
  int peek (int a) {
    this.addr = a & 0xFFFF;
    // if ROM paging selected for UpperROM, then read from the chosen Page (upperROMsel)
    if (this.isInRange(a, 0xC000, 0xFFFF) && this.upperROMpaging) {
      return (this.uproms[this.upperROMsel].data[this.addr & 0x3FFF] & 0xFF);
    // if ROM paging selected for LowerROM, then read from it
    } else if (this.isInRange(a, 0x0000, 0x3FFF) && this.lowerROMpaging) {
      return (this.lorom.data[this.addr & 0x3FFF] & 0xFF);
    // in any other case read the RAM
    } else {
      return (this.ram.data[this.addr] & 0xFF);
    }
  }

  // can only poke in RAM
  void poke (int a, int val) {
    this.addr = a & 0xFFFF;
    this.ram.data[this.addr] = val & 0xFF;
  }

  // can only poke in RAM
  // poke into memory from addr (incrementing) the given list of byte data.
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
    for (int i = 0; i < 0x40; i++) {
      // copy the RST table from AMDOS to RAM
      this.poke(i, this.rompeek(3, 7, i));
    }
  }

  void memDump () {
    this.memdmp = createWriter("data/MemDump.txt"); // Create a new file in the sketch directory
    int val8;
    for (int a = 0; a < 0x10000; a++) {
      if (a % 16 == 0) {
        this.memdmp.print(hex(a, 4) + " : ");
      }
      val8 = this.peek(a);
      this.memdmp.print(hex(val8, 2) + " ");
      if ((a + 1) % 16 == 0) {
        this.memdmp.println("");
      }
    }
    this.memdmp.flush(); // Writes the remaining data to the file
    this.memdmp.close(); // Finishes the file
  }

  // peek can be done in rom or ram
  int rompeek (int bank, int page, int a) {
    this.addr = a & 0x3FFF;
    if (bank == 0) {
      return (this.lorom.data[this.addr] & 0xFF);
    } else {
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
    this.romdmp = createWriter("data/RomDump.txt"); // Create a new file in the sketch directory
    this.romDumpRom(0, 0);
    this.romDumpRom(3, 0);
    this.romDumpRom(3, 7);
    this.romdmp.flush(); // Writes the remaining data to the file
    this.romdmp.close(); // Finishes the file
  }

  // 1 bank = 16384 bytes, 4 banks = 65536 bytes or 64kB
  // returns the bank number from the address (0 to 3)
  int addr2bank (int a) {
    return floor(a / 0x4000);
  }
  // returns the addr offset in the current bank (0x0000 to 0x3FFF) 
  int addr2offbank (int a) {
    return (a % 0x4000);
  }

/*
 ;This register exists only in CPCs with 128K RAM (like the CPC 6128, 
 ;or CPCs with Standard Memory Expansions). 
 ;Note: In the CPC 6128, the register is a separate PAL that assists 
 ;the Gate Array chip.
 ;The 3bit RAM Config value is used to access the total of 128K RAM 
 ;(RAM Banks 0-7) that is built into the CPC 6128. Normally the register 
 ;is set to 0, so that only the first 64K RAM are used (identical to the
 ;CPC 464 and 664 models). The register can be used to select between the 
 ;following eight predefined configurations only:
    // conf : banks
    // 0 : 0 1 2 3  ** DEFAULT; 464 Mode
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
  */
  void selExtRAMConfig (int page, int s, int bank) {
  }

  void addr2zone (int a) {
    if ((a >= 0x0000) && (a <= 0x003F)) {
      log.logln("RESTART RST"); // RST 0 : init CPC; RST 0x38 : saut du mode IM1
    } else if ((a >= 0x0040) && (a <= 0x016F)) {
      log.logln("Tampon de convertion des saisies clavier en BASIC");
    } else if ((a >= 0x0170) && (a <= 0xA6FF)) {
      log.logln("Zone de travail du BASIC (programme, variables, etc.");
      if ((a >= 0x4000) && (a <= 0x7FFF)) {
        log.logln("Cette partie peux être paginée (6128 only) pour accéder à 64kB supplémentaire grace à une OUT &7F00,&C0 (normal, bank 1), ou &C4 à &C7 pour extended bank 0 à 3. Peut aussi être utilisée pour la video (voir vecteur BC08)");
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

  void testASM () {
    int pc = 0;
    cpc.mem.poke(pc++, 0x00);       // NOP
    cpc.mem.poke(pc++, 0x21);
    cpc.mem.poke(pc++, 0x00);
    cpc.mem.poke(pc++, 0xC0);       // LD HL, 0xC000
    cpc.mem.poke(pc++, 0x3E);
    cpc.mem.poke(pc++, 0x55);       // LD A, 0x55
    cpc.mem.poke(pc++, 0x06);
    cpc.mem.poke(pc++, 0x44);       // LD B, 0x44
    cpc.mem.poke(pc++, 0x04);       // INC B
    cpc.mem.poke(pc++, 0x80);       // ADD A, B
    cpc.mem.poke(pc++, 0x77);       // LD (HL), A
    cpc.mem.poke(pc++, 0x23);       // INC HL
    cpc.mem.poke(pc++, 0x18);
    cpc.mem.poke(pc++, 250);        // JR -6
    cpc.mem.poke(pc++, 0x00);
  }
}