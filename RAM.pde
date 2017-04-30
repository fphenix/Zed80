// RAM

class RAM {
  int[] data;
  int bank;
  int addr;
  Firmware rom;
  PrintWriter memdmp;

  RAM (Firmware romref) {
    this.rom = romref;
    this.data = new int[64 * 1024]; // 64kB of memory
    this.addr = 0x0000;
    this.memdmp = null;
  }

  int peek (int a) {
    this.addr = a & 0xFFFF;
    return (this.data[this.addr] & 0xFF);
  }

  void poke (int a, int val) {
    this.addr = a & 0xFFFF;
    this.data[this.addr] = val & 0xFF;
  }

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
      if (this.rom.isVector(a)) {
        this.poke(a, 0xC9);
      }
    }
  }

  void testASM () {
    int pc = 0;
    cpc.ram.poke(pc++, 0x00);       // NOP
    cpc.ram.poke(pc++, 0x21);
    cpc.ram.poke(pc++, 0x00);
    cpc.ram.poke(pc++, 0xC0);       // LD HL, 0xC000
    cpc.ram.poke(pc++, 0x3E);
    cpc.ram.poke(pc++, 0x55);       // LD A, 0x55
    cpc.ram.poke(pc++, 0x06);
    cpc.ram.poke(pc++, 0x44);       // LD B, 0x44
    cpc.ram.poke(pc++, 0x04);       // INC B
    cpc.ram.poke(pc++, 0x80);       // ADD A, B
    cpc.ram.poke(pc++, 0x77);       // LD (HL), A
    cpc.ram.poke(pc++, 0x23);       // INC HL
    cpc.ram.poke(pc++, 0x18);
    cpc.ram.poke(pc++, 250);        // JR -6
    cpc.ram.poke(pc++, 0x00);
  }
}