// Used by class Z80

class Opcodes {
  // instanciation
  Instruction instr;
  Cycles cycle;

  // reference
  Registers reg;
  Pinout pin;
  Memory mem;
  Firmware fwv;

  int opcode, opcode2;
  int pc;
  int prevpc = -1;
  boolean saidLooping = false;
  String prevmsg = "";

  // =============================================================================================
  Opcodes () {
    this.instr = new Instruction();
    this.opcode = 0x00;
    this.cycle = new Cycles();
  }

  void setRef(Registers regref, Pinout pinref, Memory memref, Firmware fwvref) {
    this.reg = regref;
    this.pin = pinref;
    this.mem = memref;
    this.fwv = fwvref;
    this.instr.setRef(regref, pinref, memref, fwvref);
  }

  // =============================================================================================
  void OpCodeSel (int[] opc) {
    this.opcode  = opc[0];
    this.opcode2 = opc[1];
    this.pc = this.reg.specialReg[this.reg.PCpos];
    int r, s, d, b, c, p, q, m, ixy, en, mode;

    // -- NOP -------------------------------------------------------------------------------------
    // -- 0000_0000 : 0x00
    if (this.opcode == 0x00) {
      this.instr.NOP();

      // -- LD r8, s8 and HALT -----------------------------------------------------------------------------
      // -- 01rr_rsss : 0x40 to 0x7F
    } else if ((this.opcode & 0xC0) == 0x40) {
      r = (this.opcode & 0x38) >> 3;
      s = this.opcode & 0x07;
      if ((r != this.reg.contHLpos) && (s != this.reg.contHLpos)) {
        this.instr.LDrs(r, s);
      } else if ((r == this.reg.contHLpos) && (s == this.reg.contHLpos)) {
        this.instr.HALT();
      } else if (r == this.reg.contHLpos) {
        this.instr.LDinContentHL(s);
      } else {
        this.instr.LDfromContentHL(r);
      }

      // -- LD r8, val8 -------------------------------------------------------------------------------------
      // -- 00rr_r110 vvvv_vvvv : 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E
    } else if ((this.opcode & 0xC7) == 0x06) {
      r = (this.opcode & 0x38) >> 3;
      this.instr.LDrval(r, opc[1]);

      // -- LD r16, val16 -----------------------------------------------------------------------------------
      // -- 00dd_0001 llll_llll hhhh_hhhh : 0x01, 0x11, 0x21, 0x31
    } else if ((this.opcode & 0xCF) == 0x01) {
      d = (this.opcode & 0x30) >> 4;
      this.instr.LDdval(d, opc[1], opc[2]);

      // -- LD HL, (val16) -----------------------------------------------------------------------------------
      // -- 0010_1010 llll_llll hhhh_hhhh : 0x2A
    } else if (this.opcode == 0x2A) {
      this.instr.LDHLcontval(opc[1], opc[2]);

      // -- LD A, (val16) -----------------------------------------------------------------------------------
      // -- 0011_1010 llll_llll hhhh_hhhh : 0x3A
    } else if (this.opcode == 0x3A) {
      this.instr.LDAcontval(opc[1], opc[2]);

      // -- LD A, (d) -----------------------------------------------------------------------------------
      // -- 000d_1010 : 0x0A, 0x1A
    } else if ((this.opcode & 0xEF) == 0x0A) {
      d = (this.opcode & 0x10) >> 4;
      this.instr.LDAcontd(d);

      // -- LD (val16), HL -----------------------------------------------------------------------------------
      // -- 0010_0010 llll_llll hhhh_hhhh : 0x22
    } else if (this.opcode == 0x22) {
      this.instr.LDcontvalHL(opc[1], opc[2]);

      // -- LD (val16), A -----------------------------------------------------------------------------------
      // -- 0011_0010 llll_llll hhhh_hhhh : 0x32
    } else if (this.opcode == 0x32) {
      this.instr.LDcontvalA(opc[1], opc[2]);

      // -- LD (d), A -----------------------------------------------------------------------------------
      // -- 000d_0010 : 0x02, 0x12
    } else if ((this.opcode & 0xEF) == 0x02) {
      d = (this.opcode & 0x10) >> 4;
      this.instr.LDcontdA(d);

      // -- LD SP, HL -----------------------------------------------------------------------------------
      // -- 1111_1001 : 0xF9
    } else if (this.opcode == 0xF9) {
      this.instr.LDSPHL();

      // -- ADD A, r8 -------------------------------------------------------------------------------------
      // -- 1000_0rrr : 0x80 to 0x87
    } else if ((this.opcode & 0xF8) == 0x80) {
      r = (this.opcode & 0x07);
      this.instr.ADDAr(r);

      // -- ADC A, r8 -------------------------------------------------------------------------------------
      // -- 1000_1rrr : 0x88 to 0x8F
    } else if ((this.opcode & 0xF8) == 0x88) {
      r = (this.opcode & 0x07);
      this.instr.ADDAr(r);

      // -- ADD A, val8 -------------------------------------------------------------------------------------
      // -- 1100_0110 vvvv_vvvv : 0xC6
    } else if (this.opcode == 0xC6) {
      this.instr.ADDAval(opc[1]);

      // -- ADD HL, ss -------------------------------------------------------------------------------------
      // -- 00ss_1001 : 0x09, 0x19, 0x29, 0x39
    } else if ((this.opcode & 0xCF) == 0x09) {
      s = (this.opcode & 0x30) >> 4;
      this.instr.ADDHLs(s);

      // -- INC r -------------------------------------------------------------------------------------
      // -- 00rr_r100 : 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C
    } else if ((this.opcode & 0xC7) == 0x04) {
      r = (this.opcode & 0x38) >> 3;
      this.instr.INCr(r);

      // -- DEC r -------------------------------------------------------------------------------------
      // -- 00rr_r101 : 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D
    } else if ((this.opcode & 0xC7) == 0x05) {
      r = (this.opcode & 0x38) >> 3;
      this.instr.DECr(r);

      // -- INC s -------------------------------------------------------------------------------------
      // -- 00ss_0011 : 0x03, 0x13, 0x23, 0x33
    } else if ((this.opcode & 0xCF) == 0x03) {
      s = (this.opcode & 0x30) >> 4;
      this.instr.INCs(s);

      // -- DEC s -------------------------------------------------------------------------------------
      // -- 00ss_1011 : 0x0B, 0x1B, 0x2B, 0x3B
    } else if ((this.opcode & 0xCF) == 0x0B) {
      s = (this.opcode & 0x30) >> 4;
      this.instr.DECs(s);

      // -- ADC A, val8 -------------------------------------------------------------------------------------
      // -- 1100_1110 vvvv_vvvv : 0xCE
    } else if (this.opcode == 0xCE) {
      this.instr.ADCAval(opc[1]);

      // -- SUB r8 -------------------------------------------------------------------------------------
      // -- 1001_0rrr : 0x90 to 0x97
    } else if ((this.opcode & 0xF8) == 0x90) {
      r = (this.opcode & 0x07);
      this.instr.SUBr(r);

      // -- SBC A, r8 -------------------------------------------------------------------------------------
      // -- 1001_1rrr : 0x98 to 0x9F
    } else if ((this.opcode & 0xF8) == 0x98) {
      r = (this.opcode & 0x07);
      this.instr.SBCAr(r);

      // -- SUB val8 -------------------------------------------------------------------------------------
      // -- 1101_0110 vvvv_vvvv : 0xD6
    } else if (this.opcode == 0xD6) {
      this.instr.SUBval(opc[1]);

      // -- SBC val8 -------------------------------------------------------------------------------------
      // -- 1101_1110 vvvv_vvvv : 0xDE
    } else if (this.opcode == 0xDE) {
      this.instr.SBCAval(opc[1]);

      // -- DAA -------------------------------------------------------------------------------------
      // -- 0010_0111 : 0x27
    } else if (this.opcode == 0x27) {
      this.instr.DAA();

      // -- EX DE, HL -------------------------------------------------------------------------------------
      // -- 1110_1011 : 0xEB
    } else if (this.opcode == 0xEB) {
      this.instr.EXDEHL();

      // -- EX AF, A'F' -------------------------------------------------------------------------------------
      // -- 0000_1000 : 0x08
    } else if (this.opcode == 0x08) {
      this.instr.EXAFAFp();

      // -- EX (SP), HL -------------------------------------------------------------------------------------
      // -- 1110_0011 : 0xE3
    } else if (this.opcode == 0xE3) {
      this.instr.EXcontSPHL();

      // -- EXX -------------------------------------------------------------------------------------
      // -- 1101_1001 : 0xD9
    } else if (this.opcode == 0xD9) {
      this.instr.EXX();

      // -- CPL -------------------------------------------------------------------------------------
      // -- 0010_1111 : 0x2F
    } else if (this.opcode == 0x2F) {
      this.instr.CPL();

      // -- CCF -------------------------------------------------------------------------------------
      // -- 0011_1111 : 0x3F
    } else if (this.opcode == 0x3F) {
      this.instr.CCF();

      // -- SCF -------------------------------------------------------------------------------------
      // -- 0011_0111 : 0x37
    } else if (this.opcode == 0x37) {
      this.instr.SCF();

      // -- EI and DI -------------------------------------------------------------------------------------
      // -- 1111_1011 : 0xFB
      // -- 1111_0011 : 0xF3
    } else if ((this.opcode & 0xF7) == 0xF3) {
      en = ((this.opcode & 0x08) >> 3);
      this.instr.EIDI(en);

      // -- RLCA, RRCA, RLA, RRA -----------------------------------------------------------------------
      // -- 000r_r111 : 0x07, 0x0F, 0x17, 0x1F
    } else if ((this.opcode & 0xE7) == 0x07) {
      mode = (this.opcode & 0x18) >> 3;
      this.instr.RandSA(mode); 

      // -- AND r8 -------------------------------------------------------------------------------------
      // -- 1010_0rrr : 0xA0 to 0xA7
    } else if ((this.opcode & 0xF8) == 0xA0) {
      r = (this.opcode & 0x07);
      this.instr.ANDAr(r);

      // -- OR r8 -------------------------------------------------------------------------------------
      // -- 1011_0rrr : 0xB0 to 0xB7
    } else if ((this.opcode & 0xF8) == 0xB0) {
      r = (this.opcode & 0x07);
      this.instr.ORAr(r);

      // -- XOR r8 -------------------------------------------------------------------------------------
      // -- 1010_1rrr : 0xA8 to 0xAF
    } else if ((this.opcode & 0xF8) == 0xA8) {
      r = (this.opcode & 0x07);
      this.instr.XORAr(r);

      // -- CP r8 -------------------------------------------------------------------------------------
      // -- 1011_1rrr : 0xB8 to 0xBF
    } else if ((this.opcode & 0xF8) == 0xB8) {
      r = (this.opcode & 0x07);
      this.instr.CPr(r);

      // -- AND val8 -------------------------------------------------------------------------------------
      // -- 1010_0rrr vvvv_vvvv : 0xE6
    } else if (this.opcode == 0xE6) {
      this.instr.ANDAval(opc[1]);

      // -- OR val8 -------------------------------------------------------------------------------------
      // -- 1011_0rrr vvvv_vvvv : 0xF6
    } else if (this.opcode == 0xF6) {
      this.instr.ORAval(opc[1]);

      // -- XOR val8 -------------------------------------------------------------------------------------
      // -- 1010_1rrr vvvv_vvvv : 0xEE
    } else if (this.opcode == 0xEE) {
      this.instr.XORAval(opc[1]);

      // -- CP val8 -------------------------------------------------------------------------------------
      // -- 1111_1110 vvvv_vvvv : 0xFE
    } else if (this.opcode == 0xFE) {
      this.instr.CPval(opc[1]);

      // -- PUSH qq -------------------------------------------------------------------------------------
      // -- 11qq_0101
    } else if ((this.opcode & 0xCF) == 0xC5) {
      q = (this.opcode & 0x30) >> 4;
      this.instr.PUSHqq(q);

      // -- POP qq -------------------------------------------------------------------------------------
      // -- 11qq_0001
    } else if ((this.opcode & 0xCF) == 0xC1) {
      q = (this.opcode & 0x30) >> 4;
      this.instr.POPqq(q);

      // -- JP nnnn -----------------------------------------------------------------------------------
      // -- 1100_0011 llll_llll hhhh_hhhh : 0xC3
    } else if (this.opcode == 0xC3) {
      this.instr.JP(opc[1], opc[2]);

      // -- JP (HL) -----------------------------------------------------------------------------------
      // -- 1110_1001 : 0xE9
    } else if (this.opcode == 0xE9) {
      this.instr.JPcontHL();

      // -- JR ee -----------------------------------------------------------------------------------
      // -- 0001_1000 eeee_eeee : 0x18
    } else if (this.opcode == 0x18) {
      this.instr.JR(opc[1]);

      // -- DJNZ ee -----------------------------------------------------------------------------------
      // -- 0001_0000 eeee_eeee : 0x10
    } else if (this.opcode == 0x10) {
      this.instr.DJNZ(opc[1]);

      // -- JP ccc, nnnn -----------------------------------------------------------------------------------
      // -- 11cc_c010 llll_llll hhhh_hhhh : 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA
    } else if ((this.opcode & 0xC7) == 0xC2) {
      c = ((this.opcode & 0x38) >> 3); 
      this.instr.JPCond(c, opc[1], opc[2]);

      // -- JR cc, ee -----------------------------------------------------------------------------------
      // -- 001s_s000 eeee_eeee : 0x20 (NZ), 0x28 (Z), 0x30 (NC), 0x38 (C)
    } else if ((this.opcode & 0xE7) == 0x20) {
      c = ((this.opcode & 0x18) >> 3); // don't look at b5 which=1 coz only have "JR NZ/Z/NC/C, ee"
      this.instr.JRCond(c, opc[1]);

      // -- CALL nnnn -----------------------------------------------------------------------------------
      // -- 1100_1101 llll_llll hhhh_hhhh : 0xCD
    } else if (this.opcode == 0xCD) {
      this.instr.CALLnn(opc[1], opc[2]);

      // -- RET --------------------------------------------------------------------------------------
      // -- 1100_1001 : 0xC9
    } else if (this.opcode == 0xC9) {
      this.instr.RET();

      // -- CALL cc,nnnn -----------------------------------------------------------------------------------
      // -- 11cc_c100 llll_llll hhhh_hhhh : 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC
    } else if ((this.opcode & 0xC7) == 0xC4) {
      c = ((this.opcode & 0x38) >> 3); 
      this.instr.CALLcccnn(c, opc[1], opc[2]);

      // -- RET cc --------------------------------------------------------------------------------------
      // -- 11cc_c000 : 0xC0, 0xC8, 0xD0, 0xD8, 0xE0, 0xE8, 0xF0, 0xF8
    } else if ((this.opcode & 0xC7) == 0xC0) {
      c = ((this.opcode & 0x38) >> 3); 
      this.instr.RETccc(c);

      // -- RST p --------------------------------------------------------------------------------------
      // -- 11pp_p111 : 0xC7, 0xCF, D7, DF, E7, EF, F7, 0xFF
    } else if ((this.opcode & 0xC7) == 0xC7) {
      p = ((this.opcode & 0x38) >> 3); 
      this.instr.RSTp(p);

      // -- IN A,(n) --------------------------------------------------------------------------------------
      // -- 1101_1011 nnnn_nnnn : 0xDBnn
    } else if (this.opcode == 0xDB) {
      this.instr.INAn(opc[1]);

      // -- OUT (n),A --------------------------------------------------------------------------------------
      // -- 1101_0011 nnnn_nnnn : 0xD3nn
    } else if (this.opcode == 0xD3) {
      this.instr.OUTnA(opc[1]);

      // ***************************************************************************************
      // **    Prefix 0xCB
      // ***************************************************************************************
    } else if (this.opcode == 0xCB) {

      // -- RLC, RL, RRC, RR, SLA, SRA, SRL, SLL ------------------------------------------------------------
      // -- 1100_1011 00mm_mrrr : 0xCB00 to 0xCB3F
      if  ((this.opcode2 & 0xC0) == 0x00) {
        m = (this.opcode2 & 0x38) >> 3;
        r = (this.opcode2 & 0x07) >> 0;
        this.instr.RandSr(m, r);

        // -- BIT b, r -----------------------------------------------------------------------------------
        // -- 1100_1011 01bb_brrr : 0xCB40 to 0xCB7F
      } else if  ((this.opcode2 & 0xC0) == 0x40) {
        b = (this.opcode2 & 0x38) >> 3;
        r = (this.opcode2 & 0x07) >> 0;
        this.instr.BITbr(b, r);

        // -- SET b, r -----------------------------------------------------------------------------------
        // -- 1100_1011 11bb_brrr : 0xCBC0 to 0xCBFF
      } else if  ((this.opcode2 & 0xC0) == 0xC0) {
        b = (this.opcode2 & 0x38) >> 3;
        r = (this.opcode2 & 0x07) >> 0;
        this.instr.SETbr(b, r);

        // -- RES b, r -----------------------------------------------------------------------------------
        // -- 1100_1011 10bb_brrr : 0xCB80 to 0xCBBF
      } else if  ((this.opcode2 & 0xC0) == 0x80) {
        b = (this.opcode2 & 0x38) >> 3;
        r = (this.opcode2 & 0x07) >> 0;
        this.instr.RESbr(b, r);

        // --NOP by default ---------------------------------------------------------------------
      } else {
        this.instr.NOTIMP(2);
      }

      // ***************************************************************************************
      // **    Prefix 0xED
      // ***************************************************************************************
    } else if (this.opcode == 0xED) {

      // -- LD r16, (val16) -----------------------------------------------------------------------------------
      // -- 1110_1101 01dd_1011 llll_llll hhhh_hhhh : 0xED4B, ED5B, ED6B, ED7B
      if  ((this.opcode2 & 0xCF) == 0x4B) {
        d = (this.opcode2 & 0x30) >> 4;
        this.instr.LDdcontval(d, opc[2], opc[3]);

        // -- LD (val16), r16 -----------------------------------------------------------------------------------
        // -- 1110_1101 01dd_0011 llll_llll hhhh_hhhh : 0xED43, ED53, ED63, ED73
      } else if ((this.opcode2 & 0xCF) == 0x43) {
        d = (this.opcode2 & 0x30) >> 4;
        this.instr.LDcontvald(d, opc[2], opc[3]);

        // -- LD A, I; LD A, R; LD I, A; LS R, A ---------------------------------------------------------------
        // -- 1110_1101 0101_0111 : 0xED57, 0xED5F, 0xED47, 0xED4F
      } else if ((this.opcode2 & 0xE7) == 0x47) {
        int air = (this.opcode2 & 0x18) >> 3;
        switch (air) {
        case 0:
          this.instr.LDIA();
          break;
        case 1:
          this.instr.LDRA();
          break;
        case 2:
          this.instr.LDAI();
          break;
        default: 
          this.instr.LDAR();
        }

        // -- LDI, LDD, LDIR, LDDR, CPI, CPD, CPIR, CPDR ---------------------------------------------------------------
        // -- 1110_1101 101r_d00c : 0xEDA0, A1, A8, A9, B0, B1, B8, B9
      } else if ((this.opcode2 & 0xE6) == 0xA0) {
        d = (this.opcode2 & 0x08) >> 3; // d=1 if "Decrement" else 0 for "Increment" instruction
        r = (this.opcode2 & 0x10) >> 4; // r=1 if "Repeat" Instruction, else 0
        c = (this.opcode2 & 0x01) >> 0; // c=1 if "ComPare" Instruction, 0 for "LoaD"
        s = (c << 2) + (r << 1) + (d << 0); // s (select) is composed by the 3 bits "crd" and allows to select the correct instruction
        switch (s) {
        case 0:
          this.instr.LDI();
          break;
        case 1:
          this.instr.LDD();
          break;
        case 2:
          this.instr.LDIR();
          break;
        case 3:
          this.instr.LDDR();
          break;
        case 4:
          this.instr.CPI();
          break;
        case 5:
          this.instr.CPD();
          break;
        case 6:
          this.instr.CPIR();
          break;
        default: 
          this.instr.CPDR();
        }

        // -- NEG -------------------------------------------------------------------------------------
        // -- 1110_1101 01??_?100 : 0xED44 (and also 0xED54, 64, 74, 4C, 5C, 6C, 7C)
      } else if ((this.opcode2 & 0xC7) == 0x44) {
        this.instr.NEG();

        // -- RLD, RRD -------------------------------------------------------------------------------
        // -- 1110_1101 0110_d111 : 0xED6F, 0xED67
      } else if ((this.opcode2 & 0xF7) == 0x67) {
        d = ((this.opcode2 & 0x08) >> 3); // 0: RRD, 1: RLD
        this.instr.RlrD(d);

        // -- IN r,(C) and IN F, (C) or IN (C) -------------------------------------------------------------
        // -- 1110_1101 01rr_r000 : 0xED40, 48, 50, 58, 60, 68, 70 (F), 78
      } else if ((this.opcode2 & 0xC7) == 0x40) {
        r = (this.opcode2 & 0x38) >> 3;
        this.instr.INrC(r);

        // -- OUT (C),r and OUT (C), 0 ----------------------------------------------------------------------
        // -- 1110_1101 01rr_r001 : 0xED41, 49, 51, 59, 61, 69, 71 (0), 79
      } else if ((this.opcode2 & 0xC7) == 0x41) {
        r = (this.opcode2 & 0x38) >> 3;
        this.instr.OUTCr(r);

        // -- RETI & RETN ----------------------------------------------------------------------
        // -- 1110_1101 0100_1101 : 0xED4D : RETI
        // -- 1110_1101 01??_?101 : 0xED45, undoc : 55, 5D, 65, 6D, 75, 7D : RETN
      } else if ((this.opcode2 & 0xC7) == 0x45) {
        m  = (this.opcode2 & 0x38) >> 3;
        if (m == 1) {
          this.instr.RETI();
        } else {
          this.instr.RETN();
        }

        // -- IM m  (m : 1, 2 or 0) -----------------------------------------------------------
        // -- 1110_1101 01?0_?110 : 0xED46, undoc : 66, 4E, 6E : IM 0
        // -- 1110_1101 01?1_0110 : 0xED56, undoc : 76 : IM 1
        // -- 1110_1101 01?1_1110 : 0xED5E, undoc : 7E : IM 2
      } else if ((this.opcode2 & 0xC7) == 0x46) {
        m = (this.opcode2 & 0x18) >> 3;
        if ((m & 0x02) == 0x00) {
          mode = 0;
        } else if ((m & 0x01) == 0x00) {
          mode = 1;
        } else {
          mode = 2;
        }
        this.instr.IMm(mode);

        // --NOP by default ---------------------------------------------------------------------
      } else {
        this.instr.NOTIMP(2);
      }

      // ***************************************************************************************
      // **    Prefix 0xDD and 0xFD
      // ***************************************************************************************
    } else if ((this.opcode & 0xDF) == 0xDD) {
      ixy = (this.opcode & 0x20) >> 5; // IX (0) or IY (1)

      // -- EX (SP), IX and EX (SP), IY --------------------------------------------------------------
      // -- 1101_1101 1110_0011 : 0xDDE3
      // -- 1111_1101 1110_0011 : 0xFDE3
      if (this.opcode2 == 0xE3) {
        this.instr.EXcontSPIXY(ixy);

        // -- POP IX and POP IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 1110_0001 : 0xDDE1, 0xFDE1
      } else if (this.opcode2 == 0xE1) {
        this.instr.POPIXY(ixy);

        // -- INC IX and INC IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 0010_0011 : 0xDD23, 0xFD23
      } else if (this.opcode2 == 0x23) {
        this.instr.INCIXY(ixy);

        // -- DEC IX and DEC IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 0010_1011 : 0xDD2B, 0xFD2B
      } else if (this.opcode2 == 0x2B) {
        this.instr.DECIXY(ixy);

        // -- PUSH IX and PUSH IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 1110_0101 : 0xDDE5, 0xFDE5
      } else if (this.opcode2 == 0xE5) {
        this.instr.PUSHIXY(ixy);

        // -- JP (IX) and JP (IY) -----------------------------------------------------------------------------------
        // -- 11i1_1101 1110_1001 : 0xDDE9, 0xFDE9
      } else if (this.opcode2 == 0xE9) {
        this.instr.JPcontIXY(ixy);

        // -- LD SP, IX and LD SP, IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 1111_1001 : 0xDDF9, 0xFDF9
      } else if (this.opcode2 == 0xF9) {
        this.instr.LDSPIXY(ixy);

        // -- LD IX, val16 and LD IY, val16 -----------------------------------------------------------------------------------
        // -- 11i1_1101 0010_0001 llll_llll hhhh_hhhh : 0xDD21, 0xFD21
      } else if (this.opcode2 == 0x21) {
        this.instr.LDIXYval(ixy, opc[2], opc[3]);

        // -- LD IX, (val16) and LD IY, (val16) -----------------------------------------------------------------------------------
        // -- 11i1_1101 0010_1010 llll_llll hhhh_hhhh : 0xDD2A, 0xFD2A
      } else if (this.opcode2 == 0x2A) {
        this.instr.LDIXYcontval(ixy, opc[2], opc[3]);

        // -- LD IX, (val16) and LD IY, (val16) -----------------------------------------------------------------------------------
        // -- 11i1_1101 0010_0010 llll_llll hhhh_hhhh : 0xDD22, 0xFD22
      } else if (this.opcode2 == 0x22) {
        this.instr.LDcontvalIXY(ixy, opc[2], opc[3]);

        // -- LD r, (IX+d)   and  IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 01rr_r110 dddd_dddd : 0xDDxx and 0xFDxx with xx= 0x46, 4E, 56, 5E, 66, 6E, 7E  (NOT 0x76!!)
      } else if (((this.opcode2 & 0xC7) == 0x46) && ((this.opcode2 & 0x38) != 0x30)) {
        r = (this.opcode2 & 0x38) >> 3; // r = 0, 1, 2, 3, 4, 5, 7 (not 6)
        this.instr.LDrcontIXYtc(r, ixy, opc[2]);

        // -- LD (IX+d), r  and  IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 0111_0rrr dddd_dddd : 0xDDxx and 0xFDxx with xx= 0x70, 71, 72, 73, 74, 75, 77  (NOT 0x76!!)
      } else if (((this.opcode2 & 0xF8) == 0x70) && ((this.opcode2 & 0x07) != 0x06)) {
        r = (this.opcode2 & 0x07) >> 0; // r = 0, 1, 2, 3, 4, 5, 7 (not 6)
        this.instr.LDcontIXYtcr(r, ixy, opc[2]);

        // -- LD (IX+d), n  and  IY -----------------------------------------------------------------------------------
        // -- 11i1_1101 0011_0110 dddd_dddd vvvv_vvvv : 0xDD36 and 0xFD36
      } else if (this.opcode2 == 0x36) {
        this.instr.LDcontIXYtcval(ixy, opc[2], opc[3]);

        // ***************************************************************************************
        // **    Prefix 0xDDCB and 0xFDCB
        // ***************************************************************************************
      } else if (this.opcode2 == 0xCB) {
        d = opc[2];
        b = m = (opc[3] & 0x38) >> 3;
        r = (opc[3] & 0x07) >> 0;

        // -- RLC IXY, RL, RRC, RR, SLA, SRA, SRL, SLL ------------------------------------------------------------
        // -- 11i1_1101 0100_1011 dddd_dddd 00mm_mrrr : 0xFD CB dd 00 to 3F
        if  ((opc[3] & 0xC0) == 0x00) {
          this.instr.RandSIXY (m, ixy, r, d);

          // -- BIT b, IXY -----------------------------------------------------------------------------------
          // -- 11i1_1101 0100_1011 dddd_dddd 01bb_brrr : 0xDD CB dd 40 to 7F
        } else if  ((this.opcode2 & 0xC0) == 0x40) {
          this.instr.BITbIXY(b, ixy, d);

          // -- SET b, IXY -----------------------------------------------------------------------------------
          // -- 11i1_1101 1100_1011 dddd_dddd 11bb_brrr : c0 to ff
        } else if  ((this.opcode2 & 0xC0) == 0xC0) {
          this.instr.SETbIXY(b, ixy, r, d);

          // -- RES b, IXY -----------------------------------------------------------------------------------
          // -- 11i1_1101 1100_1011 dddd_dddd 10bb_brrr : 80 to bf
        } else if  ((this.opcode2 & 0xC0) == 0x80) {
          this.instr.RESbIXY(b, ixy, r, d);

          // --NOP by default -------------------------------------------------------------------------------------
        } else {
          this.instr.NOTIMP(2);
        }

        // --NOP by default -------------------------------------------------------------------------------------
      } else {
        this.instr.NOTIMP(2);
      }

      // --NOP by default -------------------------------------------------------------------------------------
    } else {
      this.instr.NOTIMP(1);
    }

    String tmps = "";
    for (int i = 0; i <= this.instr.param; i++) {
      tmps += opc[i] + " ";
    }
    this.instr.setOpcode(tmps);
    this.displayInfo(opc);
    this.prevpc = this.pc;
    this.incrCycles();
    this.reg.update();
  }

  void incrCycles () {
    if (this.instr.Pcycles > 0) {
      this.reg.specialReg[this.reg.PCpos] += this.instr.Pcycles;
    }
    this.cycle.countM(this.instr.Mcycles);
    this.cycle.countT(this.instr.Tcycles);
    this.cycle.countR(this.instr.Rcycles);
    this.reg.reg8b[this.reg.Rpos] = this.cycle.getR();
  }

  void displayInfo(int opcd[]) {
    if (!log.getLogMode()) {
      return;
    }
    String msg = " : " + this.instr.asmInstr + " : " + this.instr.comment;
    if (this.pc == this.prevpc) {
      if (!this.saidLooping) {
        log.logln("... Looping over previous Instruction ..." +  hex(this.pc) + " " +  hex(this.prevpc));
        this.saidLooping = true;
      } else {
        this.prevmsg = msg;
        return;
      }
    } else {
      if (this.saidLooping) {
        log.logln("''''''   " + this.prevmsg);
        this.saidLooping = false;
      }
    }
    String s = "0x";
    s += hex(this.pc, 4) + " : ";
    for (int i = 0; i < abs(this.instr.Pcycles); i++) {
      s += hex(opcd[i], 2) + " ";
    }
    log.logln(s + msg);
  }
}