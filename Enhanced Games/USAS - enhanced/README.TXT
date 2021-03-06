USAS(RC-753) enhanced Version 1.03
----------------------------------
by Victor Martinez

-----------------------------------------
Change log:
Same version (1.03):
- FIXED:"PSG orgianl sound" mode doesn't work

Version 1.03:
- FIXED: The pitch of the music doesn't change with different emoticons
   (new size:3 Mbits)

Version 1.02:
- FIXED: There're a delay at the start of some songs
- FIXED: The "enter PASSWORD" routine doesn't read the keyboard correctly

Version 1.01:
- FIXED: when you open a door in "SELECT STAGE", the door will flicker
- FIXED: when you enter a PASSWORD, sometimes you'll see stranger characters
- FIXED: after GAME OVER, there are failures in game

-----------------------------------------

This patch implements:

  - SCC Music Arrangement by Koichiro
  - Enables the TURBOCPU in PANASONIC TR & 2+ and ExpertTurbo
  - TurboFIX routine (original routine by FRS)
  - Joymega support: START = pause (thanks to FX)
  - Selectable at boot: Language, sound, VDP freq., cheats...
  - Enhanced sprite routines: faster, and double buffer
  - Double PSG if a MegaflashROM SD is found (only with SCC music)
       MegaflashROM SD PSG->Music,  Internal PSG->Sound Effects
       It must be in "slot expander" mode

Attention!!: You will obtain a 2Mbit ROM with KONAMI-SCC mapper type.

This version should work correctly in any MSX2 or higher.

It's compatible with the BiFi's "Emoticons patch"

Issues: not full compatible with Game Master 2.



Thanks to: Koichiro, FRS, David Madurga,FX and Manuel Pazos.

I hope you like it!!







