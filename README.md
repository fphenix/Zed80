# Zed80

Amstrad CPC (6128) and Z80 Emulator in Processing!

Work very much in progress, although "**run"headover**" will launch Head over Heels.

Right now it's capable to :
* execute every Z80 opcodes;
* access the peripherals (GateArray, CRTC, PPI, FDC/FDD, PSG (no sound yet), Keyboard, Memories);
* manage the ROM/RAM paging(s);
* boot the firmware (lowerROM)
* process the 'cat' command (Floppy catalog = list of files on the floppy disk)
* use the AmsDOS ROM functions (upperRom n°7, especially the floppy disc functions);
* process the 'run"headover' command to launch the game
* run the loader screen of the game "Head Over Heels" (by Ocean), red from a floppy disk image (.dsk file); see Notes below.
* it then loads the game menu, and you can select "play the game", at this point there are a few screen glitches I need to look at!

Note: The picture is a beautiful 8-bit art by F. David Thorpe, which already makes this project worth it!
Note2: I no longer force the game into memory and run it directly, but instead I boot the firmware and use the AmsDOS floppy functions to load the game.

To launch the game, type '**run"headover**' at the Locomotive invite).

Warning the log file in 'on', and it quickly generates a multi-GB log file...

The frame rate needs to be adjusted.

All Z80 Opcodes/Instructions are implemented, but not all have been fully tested yet.

Keyboard (azerty) implemented but not fully tested. It is slow to react, keep pressing the key until it shows up at the invite!

Sound not yet supported (could be the next step).

Basic (upperRom n°0) not tested yet (apart from cat and run) although the corresponding ROM is connected.

For educational purposes only.

Note: I am nowhere near a Software/Java.Processing expert. I'd be glad to get any inputs.


Long live the migthy Amstrad CPCs!
