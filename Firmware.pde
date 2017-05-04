// Firmware

class Firmware {
  VectorTab vt;

  Firmware () {
    this.vt = new VectorTab();
  }

  void setRef(Z80 zref, GateArray garef, Memory memref, D7 d7ref) {
    this.vt.setRef(zref, garef, memref, d7ref);
  }

  boolean isVector(int v) {
    switch (v) {
    case 0xBA10 :
    case 0xBC06 :
    case 0xBC08 :
    case 0xBC0B :
    case 0xBC0E :
    case 0xBC32 :
    case 0xBC38 :
    case 0xBC3E :
    case 0xBC77 :
    case 0xBC7A :
    case 0xBC83 : 
    case 0xBCCE :
      return true;
    default:
      return false;
    }
  }

  void vectorTable (int addr) {
    switch (addr) {
    case 0xBA10 : 
      this.vt.vecBA10(); 
      break;
    case 0xBC06 :
      this.vt.vecBC06(); 
      break;
    case 0xBC08 :
      this.vt.vecBC08(); 
      break;
    case 0xBC0B :
      this.vt.vecBC0B(); 
      break;
    case 0xBC0E :
      this.vt.vecBC0E(); 
      break;
    case 0xBC32 :
      this.vt.vecBC32(); 
      break;
    case 0xBC38 :
      this.vt.vecBC38(); 
      break;
    case 0xBC3E :
      this.vt.vecBC3E(); 
      break;
    case 0xBC77 : 
      this.vt.vecBC77(); 
      break;
    case 0xBC7A : 
      this.vt.vecBC7A(); 
      break;
    case 0xBC83 : 
      this.vt.vecBC83(); 
      break;
    case 0xBCCE : 
      this.vt.vecBCCE(); 
      break;
    default : 
      this.vt.vecNotImp(addr);
    }
    log.logln("Firmware Call to Vector " + this.vt.hex4(addr) + " : " + this.vt.vectTitle);
  }

  // Vectors table
  /*
  BA10   {set screen Mode (no CLS on 6128)}
   BB00   {init keyboard}
   BB06   {attente d'une touche du clavier et renvoit du code dans l'accu}
   BB09   {teste si une touche est enfoncee}
   BB18   {attente d'une touche clavier}
   BB1B   {teste si une touche est enfoncee}
   BB21   {demande etat de la touche CAPS LOCK et SHIFT}
   BB24   {teste l'etat du joystick}
   BB3F   {reglage des temps de reponse et de repetition du clavier}
   BB48   {desactive la touche ESC}
   BB5A   {affiche le charactere contenu dans l'Accu a la position courante}
   BB60   {lit un caratere a la position courante}
   BB66   {fixe les limites d'une fenetre texte}
   BB69   {demande les dimensions de la fenetre texte courante}
   BB6C   {efface contenu de la fenetre active et replace le curseur en Haut a gauche}
   BB6F   {Deplace horizontalement la position du curseur}
   BB72   {Deplace verticalement la position du curseur}
   BB75   {deplace la position du curseur (horixontalement et verticalement)}
   BB78   {demande la position courante du curseur test}
   BB8A   {positionne le curseur a l'ecran}
   BB8D   {enleve le curseur a l'ecran}
   BB90   {determine le stylo (couleur) utilise pour l'ecriture texte}
   BB93   {demande le numero du stylo utilise pour l'ecriture texte}
   BB96   {determine le stylo utilise pour le fond des carateres texte}
   BB99   {demande le numero du stylo utlise pour le fond}
   BB9C   {echange les encres stylo/fond}
   BB9F   {place le mode d'ecriture opaque ou transparent pour le fond des carateres affichables}
   BBA5   {lit definition du caractere dont le code ASCII est dans l'accu}
   BBA8   {redef matrice de characteres}
   BBBA   {init du gestionnaire graphique}
   BBBD   {remise a zero du gestionnaire graphique}
   BBC0   {positionnement absolu du curseur graphique}
   BBC3   {positionnement relatif du curseur graphique}
   BBC6   {lecture de la  position du curseur graphique}
   BBC9   {positionnement de l'origine du curseur graphique}
   BBCC   {lecture de l'origine des traces}
   BBCF   {definitions des limites horizontales de la fenetre graphique}
   BBD2   {definition des limites verticales de la fenetre graphique}
   BBD5   {lecture des limites horizontales de la fenetre graphique}
   BBD8   {lecture des limites verticales de la fenetre graphique}
   BBDB   {effacement de la fenetre graphique}
   BBDE   {positionne la couleur des traces (stylo)}
   BBE1   {lecture de la couleur des traces (stylo)}
   BBE4   {positionnement de la couleur du fond}
   BBE7   {lecture de la couleur du fond Plus}
   BBEA   {positionnement d'un point a l'ecran en coordonnees absolues}
   BBED   {positionnement d'un point a l'ecran en coordonnees relatives a la position actuelle du curseur}
   BBF0   {teste un point aux coordonnees absolues specifiees}
   BBF3   {test un point aux coordonnees relatives}
   BBF6   {trace d'une droite en absolu}
   BBF9   {trace d'une droite en relatif}
   BBFC   {ecriture d'un caractere en mode graphique a la position courante du curseur graphique}
   BBFF   {init totale du gestionnaire}
   BC02   {re-init partielle}
   BC05   {positionne l'offset de depart de la memoire de video}
   BC06   {???  Switch to 'secondary' screen memory space 0x4000/0xC000}
   BC08   {positionne l'adresse de l'ecran en memoire vive}
   BC0B   {lecture de l'adresse de l'ecran en RAM}
   BC11   {lecture du mode video courant}
   BC14   {effacement de l'ecran}
   BC17   {lecture de la surface de l'ecran en caratere (lignes/colonnes)}
   BC1A   {calcule l'adresse de caratere}
   BC1D   {calcule l'adresse reelle d'un point graphique en fonction de ses coordonnees}
   BC20   {calcule de l'adresse reelle de l'octet situe a droite de celui dont on passe l'adresse}
   BC23   {calcule l'adresse reelle de l'octet situe a gauche de celui dont on passe l'adresse}
   BC26   {calcule l'adresse reelle de l'octet situe sous celui dont on passe l'adresse}
   BC29   {calcule l'adresse reelle de l'octet situe au-dessus de celui dont on passe l'adresse}
   BC2C   {remplit un octet avec la couleur demandee}
   BC2F   {renvoie un numero de couleur en fonction d'un octet rempli de pixels}
   BC35   {lecture des couleurs d'une encre}
   BC3B   {lecture des couleurs du bord}
   BC3E   {positionne la duree de clignotement des couleurs de bord}
   BC41   {lecture des durees d'exposition des couleurs du bord}
   BC44   {remplissage d'un rectangle par coordonnees}
   BC47   {remplissage d'un rectangle par adresse ecran}
   BC4A   {inversion des couleurs d'un caratere}
   BC4D   {fait scroller verticallement l'ecran de 8 pixels}
   BC50   {fait scroller verticallement une fenetre de 8 pixels}
   BC53   {conversion de la matrice d'un caractere standard en une autre compatible avec la mode courant}
   BC56   {conversion d'un caractere ecran en une matrice binaire de 8 octets}
   BC59   {positionne le mode graphique}
   BC5C   {affichage d'un point sur l'ecran}
   BC5F   {tracage d'une ligne horizontale}
   BC62   {tracage d'une ligne verticale}
   BC65   {init gestionnaire k7}
   BC68   {positionnement de la vitesse d'ecriture}
   BC6B   {affichage des messages ou non lors d'acces k7}
   BC6E   {mise en route moteur k7}
   BC71   {arret du moteur k7}
   BC74   {restauration de l'etat du moteur k7}
   BC77   {lecture du 1er bloc d'un fichier avec installation du tampon de transfert}
   BC7A   {fermeture fichier}
   BC7D   {Abandon de la lecture et fermeture du fichier actif}
   BC80   {Lecture d'un octet}
   BC83   {transfert d'un fichier en memoire}
   BC86   {annulation de la lecture d'un octet}
   BC89   {test de la fin de fichier}
   BC8C   {ouverture d'un fichier en sortie}
   BC8F   {fermeture propre d'un fichier de sorties}
   BC92   {fermeture immediate de fichier de sorties}
   BC95   {ecriture d'un caractere dans le fichier de sortie}
   BC98   {transfert d'une zone memoire vers la k7}
   BC9B   {generation du catalogue}
   BC9E   {ecriture d'un enregistrement sur bande}
   BCA1   {lecture d'un enregistrement k7}
   BCA4   {comparaision de donnees entre la memoire et le fichier}
   BCA7   {init du gestionnaire sonore}
   BCAA   {ajoute un son a la queue sonore}
   BCAD   {teste si une queue sonore est pleine}
   BCB0   {prepare l'execution d'une interruption lorsqu;une queue sonore est vide}
   BCB3   {remet les sons en route sur un canal}
   BCB6   {arret de tous les sons}
   BCB9   {remet tous les canaux sonores en marche}
   BCBC   {init d'une des 15 enveloppes d'amplitude}
   BCBF   {init d'une des 15 enveloppes de frequence}
   BCC2   {fournit d'adresse d'une enveloppe d'amplitude}
   BCC5   {fournit l'adresse d'une enveloppe de frequence}
   BCC8   {remise en forme et nettoyage de toutes les files d'interruption et des chono}
   BCCB   {recherche et initialisation de toutes les ROM de 2nd plan}
   
   BCD1   {installation d'une RSX}
   BCD4   {recherche d'un RSX dans les ROM}
   BCD7   {set up a slow interrupt (every 1/50 s)}
   BCDA   {restart a frozen slow interrupt}
   BCDD   {freezes slow interrupt}
   BCE0   {set up a fast interrupt (every 1/300 s)}
   BCE3   {restart a frozen slow interrupt}
   BCE6   {freezes fast interrupt}
   BCE9   {put a slow interruption (1/50 s), but does not initialize it}
   BCEC   {enleve un bloc d'evenement dans la liste de ceux a activer}
   BCEF   {initialise un bloc d'evenement gerable par BCE9 et BCEC}
   BCF2   {actionne un bloc d'evenement}
   BCF5   {clean up dans toutes les files d'attente d'evenements temporises}
   BCF8   {detruit un evement en l'enlevant physiquement de la file d'attente}
   BCFB   {recherche de l'evenement suivant a traiter}
   BCFE   {traite un bloc d'evenement}
   BD01   {termine le traitement d'un evenement}
   BD04   {interdiction des evenements temporises normaux}
   BD07   {reautorise les evenements temporises conventionnels}
   BD0A   {interdire un evenement}
   BD0D   {donne le temps ecoule en 1/300e de sec depuis l'allumage du CPC}
   BD10   {positionne le compteur interne a une valeur precise}
   BD13   {Charge un programme en RAM et le lance}
   BD16   {Lance un programme d'une ROM de 2nd plan}
   BD19   {synch frame with CRTC (controlleur du tube cathodique)}
   BD1C   {positionnement du mode ecran}
   BD1F   {positionnement de l'offset de la memoire video}
   BD22   {normalisation de la palette}
   BD25   {normlisation de la palette y compris le border}
   BD28   {init du detourment vers l'imprimante}
   BD2B   {envoi d'un caractere a l'imprimante avec retour}
   BD2E   {test de l'imprimante}
   BD31   {envoi d'u caratere a l'imprimante sans retour}
   BD34   {envoi d'une donnee dans le PSG AY3 W8912 (sound)}
   BD37   {reinit les blocs de saut standard}
   */
}