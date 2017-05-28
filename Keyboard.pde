class Keyboard {

  // String[][] keyBoard;
  // String[][] keyBoardMaj;
  int[] kbRows; // 10 rows of 8 colomns
  Touche[] mapJavaKb = new Touche[523];

  PSG psg; // ref
  Pinout pin; // ref

  Keyboard () {
    this.initKB();
    kbRows = new int[10];
    for (int i = 0; i < kbRows.length; i++) {
      this.kbRows[i] = 0xFF;
    }
  }

  void setRef (Pinout io, PSG gsp) {
    this.pin = io;
    this.psg = gsp;
  }

  // Bios 40051 French 6128

  void initKB() {
    int[] serialKBstrAZERTY = {
      // ligne 0
      KeyEvent.VK_UP, 
      KeyEvent.VK_RIGHT, 
      KeyEvent.VK_DOWN, 
      KeyEvent.VK_NUMPAD9, 
      KeyEvent.VK_NUMPAD6, 
      KeyEvent.VK_NUMPAD3, 
      KeyEvent.VK_ALT, // ENTER du PavNum
      KeyEvent.VK_DECIMAL, 
      // ligne 1
      KeyEvent.VK_LEFT, 
      KeyEvent.VK_INSERT, // COPY
      KeyEvent.VK_NUMPAD7, 
      KeyEvent.VK_NUMPAD8, 
      KeyEvent.VK_NUMPAD5, 
      KeyEvent.VK_NUMPAD1, 
      KeyEvent.VK_NUMPAD2, 
      KeyEvent.VK_NUMPAD0, 
      // ligne 2
      KeyEvent.VK_DELETE, // CLR
      KeyEvent.VK_ASTERISK, // * et <
      KeyEvent.VK_ENTER, // main ENTER/RETURN key 
      KeyEvent.VK_LESS, // # et >
      KeyEvent.VK_NUMPAD4, 
      KeyEvent.VK_SHIFT, 
      KeyEvent.VK_DOLLAR, // $ @ \
      KeyEvent.VK_CONTROL, 
      // ligne 3
      KeyEvent.VK_MINUS, // - et _
      KeyEvent.VK_RIGHT_PARENTHESIS, // ) et [
      KeyEvent.VK_CIRCUMFLEX, // VK_DEAD_CIRCUMFLEX
      KeyEvent.VK_P, 
      KeyEvent.VK_UNDEFINED, // ù ou | et %
      KeyEvent.VK_SEMICOLON, // ; et .
      KeyEvent.VK_EQUALS, // = et + 
      KeyEvent.VK_COLON, // : et /
      // ligne 4  :
      KeyEvent.VK_0, // à et 0
      KeyEvent.VK_9, // ç et 9
      KeyEvent.VK_O, 
      KeyEvent.VK_I, 
      KeyEvent.VK_L, 
      KeyEvent.VK_K, 
      KeyEvent.VK_COMMA, // , et ?
      KeyEvent.VK_M, 
      // ligne 5 ; 0xE8 = è; 
      KeyEvent.VK_EXCLAMATION_MARK, // ! et 8
      KeyEvent.VK_7, // è et 7
      KeyEvent.VK_U, 
      KeyEvent.VK_Y, 
      KeyEvent.VK_H, 
      KeyEvent.VK_J, 
      KeyEvent.VK_N, 
      KeyEvent.VK_SPACE, 
      // ligne 6
      KeyEvent.VK_6, // ], 6 et Joy2Up, 
      KeyEvent.VK_5, // (, 5 et Joy2Down,
      KeyEvent.VK_R, // et Joy2Left, 
      KeyEvent.VK_T, // et Joy2Right
      KeyEvent.VK_G, // et Joy2Fire0
      KeyEvent.VK_F, // et Joy2Fire1
      KeyEvent.VK_B, // et Joy2Fire2
      KeyEvent.VK_V, 
      // ligne 7
      KeyEvent.VK_4, // ' et 4
      KeyEvent.VK_3, // " et 3
      KeyEvent.VK_E, 
      KeyEvent.VK_W, 
      KeyEvent.VK_S, 
      KeyEvent.VK_D, 
      KeyEvent.VK_C, 
      KeyEvent.VK_X, 
      // ligne 8
      KeyEvent.VK_1, // & et 1
      KeyEvent.VK_2, // é et 2
      KeyEvent.VK_ESCAPE, 
      KeyEvent.VK_Q, 
      KeyEvent.VK_TAB, 
      KeyEvent.VK_A, 
      KeyEvent.VK_CAPS_LOCK, 
      KeyEvent.VK_Z, 
      // ligne 9 : the "0" are Joy1UP, Down, Left Right, Fire2 Fire1 Fire0 et DEL
      0, 0, 0, 0, 0, 0, 0, 
      KeyEvent.VK_BACK_SPACE
    };
    int idx;
    int val;
    for (int ligne = 0; ligne < 10; ligne++) {
      for (int bitnb = 0; bitnb < 8; bitnb++) {
        idx = bitnb + (8 * ligne);
        val = serialKBstrAZERTY[idx];
        if (val < 1) {
          continue;
        }
        this.mapJavaKb[val] = new Touche(ligne, bitnb);
      }
    }
  }

  void updateKBKeyPressed (int kev) {
    if (this.mapJavaKb[kev] == null) {
      return;
    }
    int ln = this.mapJavaKb[kev].getLine();
    int bp = this.mapJavaKb[kev].getBit();
    this.kbRows[ln] &= (~(1 << bp)) & 0xFF; // Clear the bit
    this.pin.kbData = this.kbRows;
  }

  void updateKBKeyReleased (int kev) {
    if (this.mapJavaKb[kev] == null) {
      return;
    }
    int ln = this.mapJavaKb[kev].getLine();
    int bp = this.mapJavaKb[kev].getBit();
    this.kbRows[ln] |= (1 << bp); // Set the bit
    this.pin.kbData = this.kbRows;
  }
}