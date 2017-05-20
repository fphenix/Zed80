class Keyboard {

  String[][] keyBoard;
  String[][] keyBoardMaj;

  Keyboard () {
    this.initKB();
  }

  void initKB() {
    String[] serialKBstrAZERTY = {"UP", "RIGHT", "DOWN", "F9", "F6", "F3", "ENTER", "DOT", "LEFT", "COPY", "F7", "F8", "F5", "F1", "F2", "F0", "CLR", "*", "RETURN", "#", "F4", "SHIFT", "$", "CTRL", "-", ")", "^", "P", "ù", "M", "=", ":", "à", "ç", "O", "I", "L", "K", ",", ";", "!", "è", "U", "Y", "H", "J", "N", "SPACE", "]", "(", "R", "T", "G", "F", "B", "V", "'", "\"", "E", "Z", "S", "D", "C", "X", "&", "é", "ESC", "A", "TAB", "Q", "CAPS", "W", "J1UP", "J1DOWN", "J1LEFT", "J1RIGHT", "J1FIRE2", "J1FIRE1", "J1FIRE0", "DEL"};
    String[] serialKBstrAZERTYMaj = {"UP", "RIGHT", "DOWN", "F9", "F6", "F3", "ENTER", "DOT", "LEFT", "COPY", "F7", "F8", "F5", "F1", "F2", "F0", "CLR", "<", "RETURN", ">", "F4", "SHIFT", "$", "CTRL", "_", "[", "^", "P", "%", "M", "+", "/", "0", "9", "O", "I", "L", "K", "?", ".", "8", "7", "U", "Y", "H", "J", "N", "SPACE", "6_J2UP", "5_J2DOWN", "J2LEFT", "J2RIGHT", "J2FIRE2", "J2FIRE1", "J2FIRE0", "V", "4", "3", "E", "Z", "S", "D", "C", "X", "1", "2", "ESC", "A", "TAB", "Q", "CAPS", "W", "J1UP", "J1DOWN", "J1LEFT", "J1RIGHT", "J1FIRE2", "J1FIRE1", "J1FIRE0", "DEL"};
    for (int ligne = 0; ligne <= 9; ligne++) {
      for (int bitnb = 0; bitnb < 8; bitnb++) {
        this.keyBoard[ligne][bitnb] = serialKBstrAZERTY[bitnb + (8 * ligne)];
        this.keyBoardMaj[ligne][bitnb] = serialKBstrAZERTYMaj[bitnb + (8 * ligne)];
      }
    }
  }
}