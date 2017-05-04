class Memory {
  RAM ram;
  ROM[] roms;
  Firmware fwv; // ref

  PrintWriter memdmp;
  PrintWriter romdmp;

  int bank; // 0 to 3
  int page; // 0 to 7
  int addr;
  int datum; // byte of data

  int sel; // ram or rom bank select

  Memory () {
    this.ram = new RAM();
    this.roms = new ROM[3];
    this.roms[0] = new ROM("Lower", "Firmware.rom");
    this.roms[1] = new ROM("Upper0", "Basic.rom");
    this.roms[2] = new ROM("Upper7", "Amdos.rom");
    this.memdmp = null;
    this.sel = 4;
  }

  void setRef (Firmware fwvref) {
    this.fwv = fwvref;
  }

  // peek can be done in rom or ram
  int peek (int a) {
    this.addr = a & 0xFFFF;
    return (this.ram.data[this.addr] & 0xFF);
  }

  // peek can be done in rom or ram
  int rompeek (int bank, int page, int a) {
    this.addr = a & 0x3FFF;
    if (bank == 0) {
      return (this.roms[0].data[this.addr] & 0xFF);
    } else {
      switch (page) {
      case 0:
        return (this.roms[1].data[this.addr] & 0xFF);
      case 7:
        return (this.roms[2].data[this.addr] & 0xFF);
      default:
        return 0;
      }
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

  void romDump () {
    this.romdmp = createWriter("data/RomDump.txt"); // Create a new file in the sketch directory
    int val8, tmpbank, tmppage;
    for (int rnb = 0; rnb < this.roms.length; rnb++) {
      this.romdmp.println("  **  ROM : " + this.roms[rnb].id);
      switch (rnb) {
      case 1:
        tmpbank = 3;
        tmppage = 0;
        break;
      case 2:
        tmpbank = 3;
        tmppage = 7;
        break;
      default:
        tmpbank = 0;
        tmppage = 0;
      }
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

/*
;  
 ;Register 3 - RAM Banking
 ;
 ;This register exists only in CPCs with 128K RAM (like the CPC 6128, or CPCs with Standard Memory Expansions). Note: In the CPC 6128, the register is a separate PAL that assists the Gate Array chip.
 ;Bit   Value   Function
 ;7   1   Gate Array function 3
 ;6   1
 ;5   -   not used (or 64K bank for Standard Memory Expansions)
 ;4   -
 ;3   -
 ;2   x   RAM Config (0..7)
 ;1   x
 ;0   x
 ;
 ;
 ;The 3bit RAM Config value is used to access the total of 128K RAM (RAM Banks 0-7) that is built into the CPC 6128. Normally the register is set to 0, so that only the first 64K RAM are used (identical to the CPC 464 and 664 models). The register can be used to select between the following eight predefined configurations only:
 ;
 ; -Address-     0      1      2      3      4      5      6      7
 ; 0000-3FFF   RAM_0  RAM_0  RAM_4  RAM_0  RAM_0  RAM_0  RAM_0  RAM_0
 ; 4000-7FFF   RAM_1  RAM_1  RAM_5  RAM_3  RAM_4  RAM_5  RAM_6  RAM_7
 ; 8000-BFFF   RAM_2  RAM_2  RAM_6  RAM_2  RAM_2  RAM_2  RAM_2  RAM_2
 ; C000-FFFF   RAM_3  RAM_7  RAM_7  RAM_7  RAM_3  RAM_3  RAM_3  RAM_3
 */