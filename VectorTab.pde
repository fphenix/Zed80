class VectorTab {
  String vectTitle;

  GateArray ga; // ref
  Registers reg; // ref
  Memory mem; // ref
  D7 d7; // ref

  String currFileName;
  int[] fileInfo;

  VectorTab () {
  }

  void setRef (Z80 zref, GateArray garef, Memory memref, D7 d7ref) {
    this.ga = garef;
    this.reg = zref.reg;
    this.mem = memref;
    this.d7 = d7ref;
  }

  /* ================================================================ */
  /* ALL VECTORS ARE NOW DEFINED BY THE REAL FIRMWARE (lower ROM) !!! */
  /* ================================================================ */



  /* void vecBA10 () {
   }*/

  /* void vecBC08 () {
   this.ga.videoAddr = (this.reg.reg8b[this.reg.Apos] & 0xC0) << 8; // should only be 0xC0 or 0x40 in A (corresponding resp. to 0xC000 and 0x4000 obvisoulsy)
   // Entry : A contient une des deux valeurs 0xC0 ou 040;
   // Exit: rien; les registres AF et HL sont modifiés.
   this.vectTitle = "???_??? : positionne l'adresse de l'écran en mémoire vive en "  + this.hex4(this.ga.videoAddr);
   } */

  /* void  vecBC0E () {   
   // Entry:
   // A contains the mode number (0, 1 or 2)
   // Exit:   AF, BC, DE  and  HL  are  corrupt,  and  all others are preserved
   this.ga.setMode(this.reg.reg8b[this.reg.Apos] & 0x03);
   this.vectTitle = "SCR_SET_MODE : changement de mode écran : mode " + this.ga.getMode();
   } */

  /* void  vecBC11 () {   
   // Entry: Aucune
   // Exit:  A contient le mode, AF modifié
   this.reg.reg8b[this.reg.Apos] = this.ga.getMode() & 0x03;
   this.vectTitle = "SCR_GET_MODE : lecture du mode écran : mode " + this.ga.getMode();
   } */

  /* void vecBC32 () {   
   this.vectTitle = "SCR_SET_INK : installe une encre PEN";
   // Entry: A contains the PEN number,  B  contains the first colour,
   // and C holds the second colour; if B and C are different, the color alternate (flashes)
   // Exit:   AF, BC, DE  and  HL  are  corrupt,  and  all others are preserved
   int pen = this.reg.reg8b[this.reg.Apos] & 0x0F;
   int col1 = this.reg.reg8b[this.reg.Bpos] & 0x1F;
   int col2 = this.reg.reg8b[this.reg.Cpos] & 0x1F;
   this.ga.setPEN(pen, col1, col2);
   this.vectTitle = "SCR_SET_INK : installe une encre PEN " + pen + ", color1 = " + col1 + ", color2 = " + col2;
   } */

  /* void vecBC38 () {   
   // Entry:  B contains the first colour,  and C contains the second colour
   // (if B and C are different, then it will alternate (flash);
   // Exit:   AF, BC, DE  and  HL  are  corrupt,  and  all others are preserved
   int col1 = this.reg.reg8b[this.reg.Bpos] & 0x1F;
   int col2 = this.reg.reg8b[this.reg.Cpos] & 0x1F;
   this.ga.setBORDER(col1, col2);
   this.vectTitle = "SCR_SET_BORDER: installation de la couleur du bord, color1 = " + col1 + ", color2 = " + col2;
   } */

  /* void vecBC3E () {   
   // Entry:  H holds the time that the  first colour is displayed,
   // L holds the time the second colour is displayed for.
   // Exit:  AF and HL  are  corrupt,  and  all  other registers are preserved
   // Notes: The length  of  time  that  each  colour  is  shown  is measured 
   // in 1/5Oths of a  second,  and  a value of 0 is taken to 
   // mean 256 * 1/50 seconds - the default value is  10 * 1/50 seconds
   int t1 = this.reg.reg8b[this.reg.Hpos];
   int t2 = this.reg.reg8b[this.reg.Lpos];
   this.ga.setFlash(t1, t2);
   this.vectTitle = "SCR_SET_FLASHING : Sets the  speed  with  which  the  border  and  PEN flash; t1 = " + t1 + ", t2 = " + t2;
   }
   */

  /* void vecBC65 () {
   this.currFileName = "";
   this.vectTitle = "Init cassette ... A faire";
   } */

  /* void vecBC77 () {
   // Input
   // HL = addr of a buffer containing the file header data starting with the filename,
   // DE holds the address of the 2K buffer destination, 
   // B  holds the filename length; a filename of 0 mean "read next file on tape"
   // Output
   // * If the file  was  opened  successfully, then Carry is 1; Zero is 0
   // HL  holds  the address of a buffer containing the file header data
   // DE holds the address of the destination  for  the  file, 
   // BC  holds the file length, and 
   // A holds the  file  type; 
   // * if the read stream is already  open  then  Carry  and  Zero  are  0, 
   // A contains an error nurnber  (664/6128  only)  and 
   // BC, DE, HL are corrupt;  
   // * if  ESC  was  pressed by the user, then Carry is 0,  Zero  is  1,  
   // A holds an error number (664/6128 only) and BC,  DE  and HL are corrupt;
   // * in all cases, IX and  the  other flags are corrupt, and the others are preserved
   this.currFileName = "";
   int currbyte;
   int fnamelength = this.reg.reg8b[this.reg.Bpos];
   int mem16 = (this.reg.reg8b[this.reg.Hpos] << 8) + this.reg.reg8b[this.reg.Lpos];
   for (int i = 0; i < fnamelength; i++) {
   currbyte = this.mem.peek(mem16+i);
   this.currFileName += char(currbyte & 0x7F);
   }
   fileInfo = this.d7.getreadFileInfo(this.currFileName); // b0: file-length; 1: loadaddr, 2: startaddr, 3:filetype
   this.reg.reg8b[this.reg.Bpos] = (fileInfo[0] >> 8) & 0xFF;
   this.reg.reg8b[this.reg.Cpos] = (fileInfo[0] >> 0) & 0xFF;
   this.reg.reg8b[this.reg.Dpos] = (fileInfo[1] >> 8) & 0xFF;
   this.reg.reg8b[this.reg.Epos] = (fileInfo[1] >> 0) & 0xFF;
   this.reg.reg8b[this.reg.Apos] = (fileInfo[3] >> 0) & 0xFF;
   this.reg.writeCF(1); // errors not yet supported!
   this.reg.writeZF(0); // errors not yet supported!
   this.vectTitle = "CAS_IN_OPEN : lecture du 1er bloc d'un fichier avec installation du tampon de transfert. filename = " + this.currFileName;
   } */

  /* void vecBC7A () {
   // No entry condition
   // Exit:
   // * If the file was closed successfully, then Carry is true and A is corrupt; 
   // * if the read stream was not open, then Carry is false, and  A  holds 
   // an  error code (664/6128 only); 
   // * in both cases, BC,  DE,  HL  and the other flags are all corrupt
   this.reg.writeCF(1); // errors not yet supported!
   this.vectTitle = "CAS_IN_CLOSE : fermeture fichier";
   } */

  /* void vecBC83 () {
   // Input
   // HL contains the address where the file is to be  placed in RAM
   // Output
   // * If the operation was  successful,  then  Carry is true, Zero is false, 
   // HL contains  the  entry address and A is corrupt; 
   // * if it was not  open,  then  Carry and Zero are  both false, 
   // HL is corrupt,  and  A  holds an error code (664/6128) or is  corrupt  (464);
   // * if  ESC was pressed, Carry is false, Zero  is  true,  
   // HL  is  corrupt, and A holds an error code (664/6128  only); 
   // * in all cases, BC, DE and IX and  the  other  flags  are  corrupt, and the
   // others are preserved
   int loadaddr = ((this.reg.reg8b[this.reg.Hpos] << 8) + this.reg.reg8b[this.reg.Lpos]) & 0xFFFF;
   this.d7.loadFile(this.currFileName, this.mem, loadaddr);
   this.reg.reg8b[this.reg.Hpos] = (fileInfo[2] >> 8) & 0xFF;
   this.reg.reg8b[this.reg.Lpos] = (fileInfo[2] >> 0) & 0xFF;
   this.reg.writeCF(1); // errors not yet supported!
   this.reg.writeZF(0); // errors not yet supported!
   this.vectTitle = "CAS_IN_DIRECT : transfert d'un fichier complet en memoire. (load=" + this.hex4(loadaddr);
   this.vectTitle += ", start=" + this.hex4(fileInfo[2]) + ")";
   } */

  /* void vecBCCE () {
   this.vectTitle = "KL_INIT_BACK : initialisation d'une ROM de 2nd plan";
   // Input
   // C contient le num/addr de selection de la ROM à initialiser
   // DE: addr du 1er octet utilisable
   // HL: addr du dernier octet utilisable
   // Output:
   // DE: addr du nouveau 1er octet utilisable
   // HL: addr du nouveau dernier octet utilisable
   // AF et B modifiés
   } */

  void vecNotImp (int a) {
    log.logln("Vector " + this.hex4(a) + " not (yet?) implemented");
  }

  // ====================================================================
  String hex2 (int val8) {
    return "0x" + hex(val8, 2);
  }

  String hex4 (int val16) {
    return "0x" + hex(val16, 4);
  }
}