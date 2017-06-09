# Zed80

Amstrad CPC (6128) and Z80 Emulator in Processing!

Work very much in progress.

Right now it's capable to :
* execute every Z80 opcodes;
* access the peripherals (GateArray, CRTC, PPI, FDC/FDD, PSG (no sound yet), Keyboard, Memories);
* manage the ROM/RAM paging(s);
* boot the firmware
* process the 'cat' command (Floppy catalog = list of files on the floppy disk)
* process the 'run"headover' command to launch the game
* run the loader screen of the game "Head Over Heels" (by Ocean), red from a floppy disk image (.dsk file); see Notes below.
* it then loads the game menu, and you can select "play the game", at this point there are a few screen glitches I need to look at!

Note: The picture is a beautiful 8-bit art by F. David Thorpe, which already makes this project worth it!
Note2: I no longer force the game into memory and run it directly, but instead I boot the firmware and use the AmsDOS floppy functions 
to load the game. However the loader screen colors are now messed up (mode 0)! This should be an easy fix. Games colors are fine though (mode 1).

Warning the log file in 'on', and it quickly generates a multi-GB log file...

The frame rate needs to be adjust.

All Z80 Opcodes/Instructions are implemented, but not all have been fully tested yet.

Keyboard (azerty) implemented but not fully tested.

Sound not yet supported (could be the next step).

For educational purposes only.

Note: I am nowhere near a Software/Java.Processing expert. I'd be glad to get any inputs.
