// used by class D7

class InfoConst {
  ////// DiskInfoLst
  public static final int INPARTDISK = 0;
  public static final int DISKINFOLEN = 7;
  public static final int MAIN = 0;
  public static final int FORMATID = 1;
  public static final int CREATOR = 2;  
  public static final int NBTRACKS = 3;
  public static final int NBSIDES = 4;
  public static final int TRACKSIZE = 5;
  public static final int UNUSED0 = 6;

  ////// TrackInfoLst
  public static final int INPARTTRACK = 1;
  public static final int TRACKINFOLEN = 12;
  //public static final int MAIN = 0;
  public static final int TRKINFOID = 1;
  public static final int UNUSED1 = 2;
  public static final int TRACKNUM = 3;
  public static final int SIDENUM = 4;
  public static final int UNUSED2 = 5;
  public static final int TSECTORSIZE = 6;
  public static final int VALIDSECTOR = 7;
  public static final int GAP3 = 8;
  public static final int FILLER = 9;
  public static final int SECTORINFO = 10; 
  public static final int SECTORDATA = 11;

  ////// SectorInfoLst
  public static final int INPARTSECTOR = 2;
  public static final int SECTORINFOLEN = 8;
  //public static final int MAIN = 0;
  public static final int TRACK = 1;
  public static final int SIDE = 2;
  public static final int SECTORID = 3;
  public static final int SSECTORSIZE = 4;
  public static final int STATREG1 = 5;
  public static final int STATREG2 = 6;
  public static final int UNUSED3 = 7;

  ////// FileInfoLst
  public static final int INPARTFILE = 3;
  public static final int FILEINFOLEN = 9;
  //public static final int MAIN = 0;
  public static final int USERNUM = 1;
  public static final int FILENAME = 2;
  public static final int FILEEXT = 3;
  public static final int EXTENSION = 4;
  public static final int LASTRECBYTECNT = 5;
  public static final int EXTENHIGH = 6;
  public static final int RECCNT = 7;
  public static final int BLOCKALLOCATED = 8;

  ////// FileHeaderInfoLst - Only if file is binary. If file is ASCII, there is no header.
  public static final int INPARTFILEHEADER = 4;
  public static final int FILEHEADERINFOLEN = 18;
  //public static final int MAIN = 0;
  public static final int FHUSERNUM = 1;
  public static final int FHFILENAME = 2;
  public static final int FHFILEEXT = 3;
  public static final int UNUSED4 = 4;
  public static final int FILETYPE = 5;
  public static final int UNUSED5 = 6;
  public static final int STARTADR = 7;
  public static final int UNUSED6 = 8;
  public static final int LENGTH1 = 9;
  public static final int AUTOSTARTADR = 10;
  public static final int UNUSED7 = 11;
  public static final int LENGTH2 = 12;
  public static final int UNUSED8 = 13;
  public static final int CHECKSUM = 14;
  public static final int UNUSED9 = 15;
  public static final int FILEDATA = 16;
  // not a real field:
  public static final int CHECKSUMDATA = 17;

  public static final int NBPARTS = INPARTFILEHEADER + 1;
  // int tmax1 = max(DISKINFOLEN, TRACKINFOLEN, SECTORINFOLEN);
  // int tmax2 = max(FILEINFOLEN, FILEHEADERINFOLEN);
  // public final int MAXNBFIELDS = max(tmax1, tmax2);
  public static final int MAXNBFIELDS = FILEHEADERINFOLEN;

  public static final int NBDIRSECTORS = 4;
}