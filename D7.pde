// Diskette //<>//

// 1 record = 128 bytes
// 1 sector = 512 bytes
// 1 block  = 2 sectors
// 1 track  = 9 sectors

class D7 {
  String d7Name;
  byte fileData[];
  int fileSize;
  boolean logFileON;
  InfoList[][] infoList;

  String[] LogFileData;
  String LogFileName;
  PrintWriter logFile;

  int nbTracks;
  int nbSides;
  int trackSize;
  int trackNum;
  int sideNum;
  int trackSectorSize;
  int validSector;
  int gap3;
  int filler;

  DataBlock[] dirDataBlocks = new DataBlock[InfoConst.NBDIRSECTORS];
  ArrayList<FileInfo> fileNameList = new ArrayList<FileInfo>();
  ArrayList<ArrayList> blockList = new ArrayList<ArrayList>();
  ArrayList<DataBlock> dataBlocks = new ArrayList<DataBlock>();

  D7 (String fn) {
    this.d7Name = fn;
    this.infoList  = new InfoList[InfoConst.NBPARTS][InfoConst.MAXNBFIELDS];
    this.logFileON = true;

    this.DiskInfo();
    this.TrackInfo();
    this.SectorInfo();
    this.FileInfo();
    this.BinFileHeaderInfo();

    this.LogFileName = "data/Logs/D7LogFile.txt";
    this.logFile = createWriter(this.LogFileName);
  }

  D7 () {
    this.infoList  = new InfoList[InfoConst.NBPARTS][InfoConst.MAXNBFIELDS];
    this.logFileON = true;

    this.DiskInfo();
    this.TrackInfo();
    this.SectorInfo();
    this.FileInfo();
    this.BinFileHeaderInfo();

    this.LogFileName = "data/Logs/D7LogFile.txt";
    this.logFile = createWriter(this.LogFileName);
  }

  void setLogFileMode (boolean onNOff) {
    this.logFileON = onNOff;
  }

  void DiskInfo () {
    this.infoList[InfoConst.INPARTDISK][InfoConst.MAIN] = new InfoList("Disk Information Block", 0x00, 0x100, "");
    this.infoList[InfoConst.INPARTDISK][InfoConst.FORMATID] = new InfoList("File Format Id", 0x00, 34, "Must start with 'MV - CPC' (or EXTENDED CPC DSK File for Extended disk format)");
    this.infoList[InfoConst.INPARTDISK][InfoConst.CREATOR] = new InfoList("Creator Utility Name", 0x22, 14, "");
    this.infoList[InfoConst.INPARTDISK][InfoConst.NBTRACKS] = new InfoList("Number of Tracks", 0x30, 1, "40, 80, 42, etc. (sometimes approximative)");
    this.infoList[InfoConst.INPARTDISK][InfoConst.NBSIDES] = new InfoList("Size of a Track", 0x31, 1, "1 or 2 sides");
    this.infoList[InfoConst.INPARTDISK][InfoConst.TRACKSIZE] = new InfoList("Disk Information Block", 0x32, 2, "Little-Endian, i.e. low byte first followed by high; All tracks will have the size; includes the 0x100-long Track Info block; (field unused in extended format)");
    this.infoList[InfoConst.INPARTDISK][InfoConst.UNUSED0] = new InfoList("not used", 0x34, 204, "0x00 (in Extended format: track size table = nbtracks*nbsides)");
  }

  void TrackInfo () {
    this.infoList[InfoConst.INPARTTRACK][InfoConst.MAIN] = new InfoList("Track Information Block", 0, 0, "All tracks must have a Track Information Block");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.TRKINFOID] = new InfoList("Track-Info Block Id", 0x00, 12, "Usually contains 'Track-Info slash-r slash-n'");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.UNUSED1] = new InfoList("not used", 0x0c, 4, "0");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.TRACKNUM] = new InfoList("Track number", 0x10, 1, "0 to NBTRACKS-1; Sometimes incorrect");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.SIDENUM] = new InfoList("Side number", 0x11, 1, "0 or 1; Sometimes incorrect");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.UNUSED2] = new InfoList("not used", 0x12, 2, "0 ; an extention gives b12 as data rate (1: Single or double density; 2:high density, 3: extended density) and b13: recording mode (1: FM; 2:MFM)");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.TSECTORSIZE] = new InfoList("Sector Size", 0x14, 1, "BPS: byte per sector; 0:128; 1:256; 2:512; 3:1024 bytes; Used to calculate Sector Data offset from Track Info Block");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.VALIDSECTOR] = new InfoList("Number of Valid sector", 0x15, 1, "SPT: Sectors per track. Number of valid sector in sector info block; usually 9, or upto 18");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.GAP3] = new InfoList("GAP#3 length", 0x16, 1, "GAP#3 length ; Used in formatting; 0x4E - Not essential");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.FILLER] = new InfoList("Filler Byte", 0x17, 1, "0xE5 - Not essential");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.SECTORINFO] = new InfoList("Sector Information", 0x18, 0xE8, "see SectorInfo array/list");
    this.infoList[InfoConst.INPARTTRACK][InfoConst.SECTORDATA] = new InfoList("Sector Data", 0x100, -1, "");
  }

  void SectorInfo () {
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.MAIN] = new InfoList("Sector Information", 0, 0, "");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.TRACK] = new InfoList("Track", 0x00, 1, "C param in NEC765 commands");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.SIDE] = new InfoList("Side", 0x01, 1, "H param in NEC765 commands");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.SECTORID] = new InfoList("SectorID", 0x02, 1, "R param in NEC765 commands");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.SSECTORSIZE] = new InfoList("Sector Size", 0x03, 1, "N param in NEC765 commands");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.STATREG1] = new InfoList("FDC Status Reg1", 0x04, 1, "From NEC765 ST1 status, b7 EN(End of cylinder); b5 D(ata)E(rror); b2 N(o)D(ata); b0 M(issing)A(ddress mark); other bits are unused");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.STATREG2] = new InfoList("FDC Status Reg2", 0x05, 1, "From NEC765 ST2 status, b5 C(ontrol)M(ark); b2? D(ata error in)D(ata field); b0 M(issing address mark in)D(ata field); other bits are unused");
    this.infoList[InfoConst.INPARTSECTOR][InfoConst.UNUSED3] = new InfoList("not used", 0x06, 2, "0x00 (in extended format: actual data length in bytes Little endian)");
  }

  void FileInfo () {
    this.infoList[InfoConst.INPARTFILE][InfoConst.MAIN] = new InfoList("", 0x00, 0x20, "");
    this.infoList[InfoConst.INPARTFILE][InfoConst.USERNUM] = new InfoList("User number", 0x00, 1, "");
    this.infoList[InfoConst.INPARTFILE][InfoConst.FILENAME] = new InfoList("Filename", 0x01, 8, "");
    this.infoList[InfoConst.INPARTFILE][InfoConst.FILEEXT] = new InfoList("Filename Extension", 0x09, 3, "");
    this.infoList[InfoConst.INPARTFILE][InfoConst.EXTENSION] = new InfoList("Extension", 0x0C, 1, "");
    this.infoList[InfoConst.INPARTFILE][InfoConst.LASTRECBYTECNT] = new InfoList("Last Record Byte count", 0x0D, 1, "CP/M+ only");
    this.infoList[InfoConst.INPARTFILE][InfoConst.EXTENHIGH] = new InfoList("Extention High byte", 0x0E, 1, "if required");
    this.infoList[InfoConst.INPARTFILE][InfoConst.RECCNT] = new InfoList("Record Count", 0x0F, 1, "");
    this.infoList[InfoConst.INPARTFILE][InfoConst.BLOCKALLOCATED] = new InfoList("Block allocated", 0x10, 16, "");
  }

  void BinFileHeaderInfo () {
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.MAIN] = new InfoList("", 0x00, 0x80, "");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.FHUSERNUM] = new InfoList("User number", 0x00, 1, "");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.FHFILENAME] = new InfoList("Filename", 0x01, 8, "");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.FHFILEEXT] = new InfoList("Filename Extension", 0x09, 3, "");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.UNUSED4] = new InfoList("not used", 0x0C, 6, "0x00");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.FILETYPE] = new InfoList("File Type", 0x12, 1, "0x00:Basic, 0x02:Binary, 0x0A:Prowort, add 0x01 for Protected, add 0x80 for FutureOS");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.UNUSED5] = new InfoList("not used", 0x13, 2, "0x00");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.STARTADR] = new InfoList("Start/Load address", 0x15, 2, "Little-Endian; usually 0x0170 for BASIC programs; can be almost anything for binary");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.UNUSED6] = new InfoList("not used", 0x17, 1, "0x00");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.LENGTH1] = new InfoList("File length", 0x18, 2, "Little-Endian; file length in byte");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.AUTOSTARTADR] = new InfoList("Auto Start address", 0x1A, 2, "Little-Endian; if file is binary a RUN command will start from this address");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.UNUSED7] = new InfoList("not used", 0x1C, 0x24, "0x00");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.LENGTH2] = new InfoList("File length", 0x40, 2, "Little-Endian; repeat of previous LENGTH field but allow files longer than 64K");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.UNUSED8] = new InfoList("not used", 0x42, 1, "0x00");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.CHECKSUM] = new InfoList("Checksum", 0x43, 2, "Little-Endian; Initialized with 0 and calculated from the sum for the data in the range 0x00-0x42 inclusive; if checksum is invalid AMSDOS assumes the file does not have an header");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.UNUSED9] = new InfoList("not used", 0x45, 0x3B, "0x00");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.FILEDATA] = new InfoList("File Data", 0x80, 0xFFFF, "");
    this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.CHECKSUMDATA] = new InfoList("", 0x00, 0x43, "checksum calculated over the first 0x48th bytes of the header");
  }

  /*#######################################################
   # Track-Sector info to Block-Halfblock (Halfblocks mean witch sector in the current block)
   # 1 block = 2 sectors. Since we can have odd number of sector per Track
   # we need this procedure to convert T/S into Block info
   # e.g.
   #    T0 SC1 -> B0 H0
   #    T0 SC2 -> B0 H1
   #    ...
   #    T0 SC9 -> B4 H0
   #    T1 SC1 -> B4 H1
   #######################################################*/
  int getBlockfromTrackSector (int tT, int tS) {
    int tmp = (9 * tT) + (tS & 0x0F) - 1;
    int block = floor(1.0 * tmp / 2);
    return block;
  }
  int getHalfBlockfromTrackSector (int tT, int tS) {
    int tmp = (9 * tT) + (tS & 0x0F) - 1;
    int halfblock = tmp % 2;
    return halfblock;
  }
  int getTrackfromBlockHalfBlock (int tB, int tH) {
    int tmp = (2 * tB) + tH;
    return floor(1.0 * tmp / 9);
  }
  int getSectorfromBlockHalfBlock (int tB, int tH) {
    int tmp = (2 * tB) + tH;
    return (tmp % 9) + 1;
  }

  void log (String str) {
    if (this.logFileON) {
      this.logFile.println(str);
      this.logFile.flush(); // comment this line if not in debug
    }
  }

  int[][][] readFile (String dname) {
    this.d7Name = "data/D7/" + dname;
    return this.readFile();
  }

  final int TRACKMAX = 42;
  final int SECTORMAX = 11;
  final int SIZEMAX = 512;

  int[][][] readFile () {
    int[][][] discData = new int[TRACKMAX][SECTORMAX][SIZEMAX];
    this.fileData = loadBytes(this.d7Name);
    this.fileSize = fileData.length;

    if (this.logFileON) {
      this.log("Reading binary file : " + this.d7Name);
    }

    discData = this.readStateMachine();
    this.directoryData();
    this.getFilesHeaderInfo();
    log.logln("Done reading! " + this.d7Name);
    this.genFiles();
    log.logln("Done writing! " + this.d7Name);

    if (this.logFileON) {
      this.logFile.flush();
      this.logFile.close();
    }
    return discData;
  }

  /* read the tracks and sectors info */
  int[][][] readStateMachine () {
    int[][][] discData = new int[TRACKMAX][SECTORMAX][SIZEMAX];
    int filePointer = 0;
    int inPart = InfoConst.INPARTDISK;
    int inField = InfoConst.FORMATID;
    int fieldSize;
    ArrayList<Integer> fieldData = new ArrayList<Integer>();
    String fieldDataStr;
    int currByte = 0;
    String fieldTitle;
    String fieldCmt;
    boolean consumingPointer = true;

    int sectorSizeLeft = 0;
    int validSectorsLeft = 0;
    int currSector = 0;
    ArrayList<Integer> sectorIDs = new ArrayList<Integer>();
    int tmpTrack, tmpSectorId, tmpBlock, tmpHalfblock;

    while (filePointer < this.fileSize) {
      fieldSize = this.infoList[inPart][inField].size;
      fieldTitle = this.infoList[inPart][inField].title;
      fieldCmt = this.infoList[inPart][inField].comment;
      fieldData.clear();
      fieldDataStr = "";
      for (int i = 0; i < fieldSize; i++) {
        currByte = this.fileData[filePointer] & 0xFF;
        fieldData.add(currByte);
        fieldDataStr += "0x" + hex(currByte, 2) + " ";
        filePointer++;
      }

      this.log(hex(filePointer-fieldSize, 8) + " " + inPart + " " + inField + " ; " + fieldTitle + " = " + fieldDataStr + "fieldSize=" + fieldSize +" ; Comments: " + fieldCmt);

      // **************************************************************************
      if (inPart == InfoConst.INPARTDISK) {
        if (inField == InfoConst.FORMATID) {
          // TODO : check if the field starts with "MV - CPC"
        } else if (inField == InfoConst.CREATOR) {
          //
        } else if (inField == InfoConst.NBTRACKS) {
          this.nbTracks = currByte;
        } else if (inField == InfoConst.NBSIDES) {
          this.nbSides = currByte;
        } else if (inField == InfoConst.TRACKSIZE) {
          this.trackSize = fieldData.get(0) + (fieldData.get(1) << 8); // in [0]: 8-LSBs; in [1]: 8-MSBs
        } else {
          //
        }
        // **************************************************************************
      } else if  (inPart == InfoConst.INPARTTRACK) {
        if (inField == InfoConst.TRKINFOID) {
          //
        } else if (inField == InfoConst.TRACKNUM) {
          this.trackNum = currByte;
        } else if (inField == InfoConst.SIDENUM) {
          this.sideNum = currByte;
        } else if (inField == InfoConst.TSECTORSIZE) {
          this.trackSectorSize = currByte;
        } else if (inField == InfoConst.VALIDSECTOR) {
          this.validSector = currByte;
        } else if (inField == InfoConst.GAP3) {
          this.gap3 = currByte;
        } else if (inField == InfoConst.FILLER) {
          this.filler = currByte;
        } else if (inField == InfoConst.SECTORINFO) {
          // Note the filePointer is at the same place for the
          // inPart = INPARTTRACK; in Field = SECTORINFO and
          // inPart = INPARTSECTOR; in Field = TRACr words
          // this step is a non-consuming pointer step.
          sectorSizeLeft = this.infoList[InfoConst.INPARTTRACK][InfoConst.SECTORINFO].size;
          validSectorsLeft = this.validSector;
          consumingPointer = false;
          currSector = 0;
          filePointer -= fieldSize;
          inPart = InfoConst.INPARTSECTOR;
          inField = InfoConst.TRACK;
        } else if (inField == InfoConst.SECTORDATA) {
          tmpTrack = this.trackNum;
          tmpSectorId = sectorIDs.get(currSector);
          tmpBlock = this.getBlockfromTrackSector(tmpTrack, tmpSectorId);
          tmpHalfblock = this.getHalfBlockfromTrackSector(tmpTrack, tmpSectorId);
          log("Sector Data saved in Block "+tmpBlock+","+tmpHalfblock+" - Track:"+tmpTrack+", Sector:0x"+hex(tmpSectorId, 2));
          this.dataBlocks.add(new DataBlock(tmpBlock, tmpHalfblock, fieldData));
println(tmpTrack,currSector, tmpSectorId, tmpBlock, tmpHalfblock, fieldData.size());
          for (int bp = 0; bp < fieldData.size(); bp++) {
            discData[tmpTrack][currSector][bp] = fieldData.get(bp);
          }
          // Note : the first 2 blocks (4 sectors) are the files directory information
          if (tmpBlock < 2) {
            int idx = (2*tmpBlock) + tmpHalfblock;
            this.dirDataBlocks[idx] = new DataBlock(tmpBlock, tmpHalfblock, fieldData);
          }
          currSector++;
          validSectorsLeft--;
          if (validSectorsLeft > 0) {
            inField = InfoConst.SECTORDATA;
          } else {
            inField = InfoConst.TRKINFOID;
          }
          consumingPointer = false;
        } else {
          //
        }
        // **************************************************************************
      } else if  (inPart == InfoConst.INPARTSECTOR) {
        sectorSizeLeft -= fieldSize;
        if (inField == InfoConst.TRACK) {
          //
        } else if (inField == InfoConst.SIDE) {
          //
        } else if (inField == InfoConst.SECTORID) {
          sectorIDs.add(currByte);
          currSector++;
        } else if (inField == InfoConst.SSECTORSIZE) {
          this.infoList[InfoConst.INPARTTRACK][InfoConst.SECTORDATA].size = (0x0080 << currByte);
        } else if (inField == InfoConst.STATREG1) {
          //
        } else if (inField == InfoConst.STATREG2) {
          //
        } else if (inField == InfoConst.UNUSED3) {
          validSectorsLeft--;
          if (validSectorsLeft > 0) {
            inField = InfoConst.TRACK;
          } else {
            filePointer += sectorSizeLeft;
            validSectorsLeft = this.validSector;
            inPart = InfoConst.INPARTTRACK;
            inField = InfoConst.SECTORDATA;
            currSector = 0;
          }
          consumingPointer = false;
          //
        } else {
          //
        }
      } else {
        //
      }

      if (consumingPointer) {
        inField++;
      }
      consumingPointer = true;

      if (inPart == InfoConst.INPARTDISK) {
        if (inField == InfoConst.DISKINFOLEN) {
          inPart = InfoConst.INPARTTRACK;
          inField = InfoConst.TRKINFOID;
        }
      } else if  (inPart == InfoConst.INPARTTRACK) {
        if (inField == InfoConst.TRACKINFOLEN) {
          inPart = InfoConst.INPARTSECTOR;
          inField = InfoConst.TRACK;
        }
      } else if  (inPart == InfoConst.INPARTSECTOR) {
        if (inField == InfoConst.SECTORINFOLEN) {
          inPart = InfoConst.INPARTFILE;
          inField = InfoConst.USERNUM;
        }
      } else if  (inPart == InfoConst.INPARTFILE) {
        if (inField == InfoConst.FILEINFOLEN) {
          inPart = InfoConst.INPARTFILEHEADER;
          inField = InfoConst.FHUSERNUM;
        }
      }
    }
    return discData; // [track][sector][bytepos];
  }

  /* Read the files info from the file allocation table (4 first sectors) */
  void directoryData () {
    int dataPointer = 0;
    int inPart = InfoConst.INPARTFILE;
    int inField = InfoConst.USERNUM;
    int fieldSize;
    ArrayList<Integer> fieldData = new ArrayList<Integer>();
    ArrayList<Integer> listBlocks = new ArrayList<Integer>();
    String fieldDataStr;
    int currByte = 0;
    String fieldTitle;
    String fieldCmt;
    String fname = "";
    String fileExt = "";
    boolean consumingPointer = true;
    int foundIdx = -1;

    ArrayList<Byte> dirData = new ArrayList<Byte>();
    int dirDataLen;
    int len = 0;
    // Note : the first 2 blocks (4 sectors) are the files directory information
    for (int i = 0; i < InfoConst.NBDIRSECTORS; i++) {
      len = this.dirDataBlocks[i].data.size();
      for (int j = 0; j < len; j++) {
        dirData.add(byte(this.dirDataBlocks[i].data.get(j)));
        dataPointer++;
      }
    }   

    dirDataLen = dirData.size();
    dataPointer = 0;
    while (dataPointer < dirDataLen) {
      fieldSize = this.infoList[inPart][inField].size;
      fieldTitle = this.infoList[inPart][inField].title;
      fieldCmt = this.infoList[inPart][inField].comment;
      fieldData.clear();
      fieldDataStr = "";
      for (int i = 0; i < fieldSize; i++) {
        currByte = dirData.get(dataPointer) & 0xFF;
        fieldData.add(currByte);
        fieldDataStr += "0x" + hex(currByte, 2) + " ";
        dataPointer++;
      }
      this.log("Data : " + fieldDataStr);
      // **************************************************************************
      if (inField == InfoConst.USERNUM) {
        this.log("============================================================");
        this.log(hex(dataPointer, 8) + " of " + dirDataLen + " in hex:" + hex(dirDataLen, 8));
        if (currByte == 0xE5) {
          this.log(fieldTitle + " = " + currByte + " : No File");
          dataPointer -= fieldSize;
          dataPointer += this.infoList[inPart][InfoConst.MAIN].size; //skip file header block
          consumingPointer = false;
          inField = InfoConst.USERNUM;
        } else {
          if ((currByte >= 0x00)&&(currByte <= 0x0F)) {
            this.log(fieldTitle + " = " + currByte + " : User Id");
          } else if ((currByte >= 0x10)&&(currByte <= 0x1F)) {
            this.log(fieldTitle + " = " + currByte + " Password Id (CP/M+)");
          } else if (currByte == 0x20) {
            this.log(fieldTitle + " = " + currByte + " Disc name Id (CP/M+)");
          } else if (currByte == 0x21) {
            this.log(fieldTitle + " = " + currByte + " Date Stamp (CP/M+)");
          } else {
            this.log("ERROR#38");
          }
        }
      } else if (inField == InfoConst.FILENAME) {
        fname = "";
        for (int i = 0; i < fieldData.size(); i++) {
          if (fieldData.get(i) != 0x20) { // skip spaces
            fname += char(fieldData.get(i));
          }
        }
      } else if (inField == InfoConst.FILEEXT) {
        fileExt = "";
        for (int i = 0; i < fieldData.size(); i++) {
          if ((fieldData.get(i) & 0x7F) != 0x20) { // skip spaces
            fileExt += char((fieldData.get(i) & 0x7F));
          } 
          if (fieldData.get(i) > 0x7F) {
            if (i == 0) {
              this.log("File is ReadOnly, and protected against deletion");
            } else if (i == 1) {
              this.log("System file, Hidden file");
            } else if (i == 2) {
              this.log("Archive");
            }
          }
        }
        fname += "." + fileExt;
        foundIdx = -1;
        for (int idx = 0; idx < this.fileNameList.size(); idx++) {
          this.log("comparing : >"+this.fileNameList.get(idx).filename +"<>"+fname+"<");
          if (fname.equals(this.fileNameList.get(idx).filename) == true) {
            foundIdx = idx;
            break;
          }
        }
        if (foundIdx < 0) {
          this.log("@@@ Create block list for " + fname + " idx " + this.fileNameList.size());
          this.fileNameList.add(new FileInfo(fname));
        } else {
          this.log("@@@ append block list for " + fname + " idx " + foundIdx);
        }
        this.log("File : " + fname);
      } else if (inField == InfoConst.EXTENSION) {
        this.log(fieldTitle + " " + currByte);
      } else if (inField == InfoConst.LASTRECBYTECNT) {
        this.log(fieldTitle + " " + currByte + " ; " + fieldCmt);
      } else if (inField == InfoConst.EXTENHIGH) {
        this.log(fieldTitle + " " + currByte);
      } else if (inField == InfoConst.RECCNT) {
        this.log(fieldTitle + " " + currByte + " => " + (128 * currByte) + " bytes");
      } else if (inField == InfoConst.BLOCKALLOCATED) {
        String tmp = "";
        for (int i = 0; i < fieldData.size(); i++) {
          if (fieldData.get(i) != 0) {
            tmp += "0x" + hex(fieldData.get(i), 2) + " ";
            if (foundIdx < 0) {
              this.log("@@@ ... Creating block list for " + fname + " idx " + (this.fileNameList.size()-1));
              listBlocks.add(fieldData.get(i));
              this.blockList.add(new ArrayList<Integer>());
              foundIdx = this.blockList.size() - 1;
            } else {
              this.log("@@@ ... appending block list for " + fname + " idx " + foundIdx);
            }
            this.blockList.get(foundIdx).add(fieldData.get(i));
          }
        }
        this.log("Block allocated = " + tmp);
        consumingPointer = false;
        inField = InfoConst.USERNUM;
      } else {
        //
      }

      if (consumingPointer) {
        inField++;
      }
      consumingPointer = true;
    }
  }

  // get first (half)block of every file and spit out the header info if any
  void getFilesHeaderInfo () {
    int dataPointer;
    int inPart;
    int inField;
    int fieldSize;
    ArrayList<Integer> fieldData = new ArrayList<Integer>();
    int currByte;
    String fieldTitle;
    String fieldCmt;
    String fieldDataStr;

    String fileName = "";
    boolean consumingPointer = true;
    ArrayList<Integer> listBlocks = new ArrayList<Integer>();
    int firstblock, firsthalfblock;
    int dataBlockPointer = 0;

    int loadadr = 0, autostartadr = 0;
    int length1 = 0, length2 = 0;
    int filetype = 0;

    for (int filenb = 0; filenb < this.fileNameList.size(); filenb++) {
      inPart = InfoConst.INPARTFILEHEADER;
      inField = InfoConst.FHUSERNUM;
      fileName = this.fileNameList.get(filenb).filename;
      listBlocks = this.blockList.get(filenb);
      firstblock = listBlocks.get(0);
      firsthalfblock = 0;
      for (int i = 0; i < this.dataBlocks.size(); i++) {
        if (this.dataBlocks.get(i).isTheOne(firstblock, firsthalfblock)) {
          dataBlockPointer = i;
          break;
        }
      }
      this.log("========================================");
      this.log("** Header for file : " + fileName);

      currByte = 0;
      dataPointer = 0;
      int checksum = 0;
      int expchecksum = 0;
      while (dataPointer < this.infoList[inPart][InfoConst.MAIN].size) {
        fieldSize = this.infoList[inPart][inField].size;
        fieldTitle = this.infoList[inPart][inField].title;
        fieldCmt = this.infoList[inPart][inField].comment;
        fieldData.clear();
        fieldDataStr = "";
        for (int i = 0; i < fieldSize; i++) {
          currByte = this.dataBlocks.get(dataBlockPointer).data.get(dataPointer) & 0xFF;
          fieldData.add(currByte);
          fieldDataStr += "0x" + hex(currByte, 2) + " ";
          dataPointer++;
        }

        if (dataPointer < this.infoList[inPart][InfoConst.CHECKSUMDATA].size) {
          for (int i = 0; i < fieldSize; i++) {
            checksum += fieldData.get(i);
          }
        }

        // **************************************************************************
        if (inField == InfoConst.FHUSERNUM) {
          if ((currByte >= 0x00) && (currByte <= 0x0F)) {
            this.log("  " + fieldTitle + " = " + currByte);
          } else {
            this.log("  ERROR 38#2");
          }
        } else if (inField == InfoConst.FHFILENAME) {
          // already parsed in directoryData(), could do it again if wanted!
        } else if (inField == InfoConst.FHFILEEXT) {
          // already parsed in directoryData(), could do it again if wanted!
        } else if (inField == InfoConst.UNUSED4) {
          //
        } else if (inField == InfoConst.FILETYPE) {
          String str = "";
          filetype = currByte;
          if ((currByte & 0x01) == 0x01) {
            str = " Protected";
          }
          currByte &= 0xFE;
          if (currByte == 0x00) {
            str = "Basic" + str;
          } else if (currByte == 0x02) {
            str = "Binary" + str;
          } else {
            str = "0x" + hex(currByte, 2) + str;
          }
          this.log("  " + fieldTitle + " : " + str);
        } else if (inField == InfoConst.UNUSED5) {
          //
        } else if (inField == InfoConst.STARTADR) {
          loadadr = fieldData.get(0) + (fieldData.get(1) << 8); // in [0]: 8-LSBs; in [1]: 8-MSBs
          this.log("  " + fieldTitle + " : 0x" + hex(loadadr, 4) + " ; " + fieldCmt);
        } else if (inField == InfoConst.UNUSED6) {
          //
        } else if (inField == InfoConst.LENGTH1) {
          length1 = fieldData.get(0) + (fieldData.get(1) << 8); // in [0]: 8-LSBs; in [1]: 8-MSBs
          this.log("  " + fieldTitle + " : 0x" + hex(length1, 4) + " ; " + fieldCmt);
        } else if (inField == InfoConst.AUTOSTARTADR) {
          autostartadr = fieldData.get(0) + (fieldData.get(1) << 8); // in [0]: 8-LSBs; in [1]: 8-MSBs
          this.log("  " + fieldTitle + " : 0x" + hex(autostartadr, 4) + " ; " + fieldCmt);
        } else if (inField == InfoConst.UNUSED7) {
          //
        } else if (inField == InfoConst.LENGTH2) {
          length2 = fieldData.get(0) + (fieldData.get(1) << 8); // in [0]: 8-LSBs; in [1]: 8-MSBs
          this.log("  " + fieldTitle + " : 0x" + hex(length2, 4) + " ; " + fieldCmt);
        } else if (inField == InfoConst.UNUSED8) {
          //
        } else if (inField == InfoConst.CHECKSUM) {
          // if wrong then file may not have an header at all,
          // e.g. ASCII/Text files data start from offset 0x00
          expchecksum = fieldData.get(0) + (fieldData.get(1) << 8); // in [0]: 8-LSBs; in [1]: 8-MSBs
          if (expchecksum == checksum) {
            this.log("  " + fieldTitle + " : 0x" + hex(checksum, 4) + " ; " + fieldCmt);
          } else {
            this.log("  CHECKSUM Error! This file may not have a Header (for instance a text/ASCII file starts at offset 0) or the file may not be a Basic or Binary file. The last options is that the file is corrupted.");
          }

          int foundIdx = -1;
          for (int idx = 0; idx < this.fileNameList.size(); idx++) {
            if (fileName.equals(this.fileNameList.get(idx).filename) == true) {
              this.fileNameList.get(idx).setInfo(loadadr, length1, autostartadr, filetype);
              foundIdx = idx;
              break;
            }
          }
          if (foundIdx < 0) {
            this.log(" Humm something's wrong, file should exist!");
          }
        } else if (inField == InfoConst.UNUSED9) {
          //
        } else {
          //
        }

        if (consumingPointer) {
          inField++;
        }
        consumingPointer = true;
      }
    }
  }

  // Generate the individual files, they can then be loaded in memory at correct location
  void genFiles () {
    int currBlock = 0;
    JSONArray json = new JSONArray();
    JSONObject currfile;
    String str = "";
    ArrayList<Integer> listBlocks = new ArrayList<Integer>();
    int b;
    int flen = 0;

    for (int idx = 0; idx < this.fileNameList.size(); idx++) {
      flen = 0;
      currfile = new JSONObject();

      currfile.setInt("id", idx);
      currfile.setString("fname", this.fileNameList.get(idx).filename);
      currfile.setInt("loadaddr", this.fileNameList.get(idx).loadadr);
      currfile.setInt("filetype", this.fileNameList.get(idx).filetype);
      currfile.setInt("length", this.fileNameList.get(idx).flength);
      currfile.setInt("startaddr", this.fileNameList.get(idx).startadr);

      str = "";
      for (int j = 0; j < this.blockList.get(idx).size(); j++) {
        listBlocks = this.blockList.get(idx);
        b = listBlocks.get(j);
        for (int hb = 0; hb < 2; hb++) {
          for (int currblk = 0; currblk < this.dataBlocks.size(); currblk++) {
            if (this.dataBlocks.get(currblk).isTheOne(b, hb)) {
              currBlock = currblk;
              break;
            }
          }
          for (int k = 0; k < this.dataBlocks.get(currBlock).data.size(); k++) {
            if ((j == 0) && (hb == 0) && (k < this.infoList[InfoConst.INPARTFILEHEADER][InfoConst.FILEDATA].offset)) {
              // skip file header
            } else if (flen < this.fileNameList.get(idx).flength) {
              str += hex(this.dataBlocks.get(currBlock).data.get(k), 2) + " ";
              flen ++;
            } else {
              // skip filler bytes after "file data length" bytes
            }
          }
        }
      }
      currfile.setString("data", str);

      json.setJSONObject(idx, currfile);
    }

    saveJSONArray(json, "./data/JSON/D7files.json");
  }

  void loadFile(String filename, Memory mem) {
    this.loadFile(filename, mem, -1);
  }

  int[] getreadFileInfo(String filename) {
    int[] fileInfo = new int[4];
    JSONArray json;
    JSONObject currfile;
    boolean found = false;
    json = loadJSONArray("./data/JSON/D7files.json");
    for (int i = 0; i < json.size(); i++) {
      currfile = json.getJSONObject(i);
      String fname = currfile.getString("fname");
      if (!filename.equals(fname)) {
        continue;
      }
      found = true;
      // int id = currfile.getInt("id");
      fileInfo[0] = currfile.getInt("length"); // int len
      fileInfo[1] = currfile.getInt("loadaddr"); // int loadaddr
      fileInfo[2] = currfile.getInt("startaddr"); // int startaddr
      fileInfo[3] = currfile.getInt("filetype"); // int filetype
      // String data = currfile.getString("data");
      break;
    }
    if (!found) {
      println("File >" + filename + "< not found! while reading Header Info");
    }
    return fileInfo;
  }

  void loadFile(String filename, Memory mem, int forceloadaddr) {
    JSONArray json;
    JSONObject currfile;
    boolean found = false;
    json = loadJSONArray("./data/JSON/D7files.json");
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

      if (forceloadaddr >= 0) {
        loadaddr = forceloadaddr;
      }

      mem.pokeList(loadaddr, data);

      log.logln("Done loading "  + fname + " @ 0x" + hex(loadaddr, 4 ) + " !");
      break;
    }
    if (!found) {
      println("File >" + filename + "< not found! while reading file data");
    }
  }
}