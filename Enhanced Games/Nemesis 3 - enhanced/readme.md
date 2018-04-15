**Nemesis 3 (RC-764) enhanced Version 1.00**


for MSX2 or higher (recommended TurboCPU)
by Victor Martinez
##

Apply the IPS patch in Nemesis 3 original ROM file. You will obtain a 3Mbit ROM.

This version should work correctly in any MSX2 or higher. For emulation, use [openMSX](https://openmsx.org/) for the best experience.

For [webMSX](http://webmsx.org/), apply the webMSX IPS patch(not the other): correct line interrupt and joymega support disabled.

[Video demostration](https://youtu.be/0IPT3a7ZkYE)


This patch implements:
  
  - TurboFIX routine (original routine by [FRS](http://frs.badcoffee.info/))
  - New player ships GFX by **Toni Galvez** (amazing new graphics in Intro, ship menu, gameplay...)
  - Voice Set (SCC in other slot/subslot) by **WYZ**/**ARTRAG**.
      - New Voicet SET with better sound quality and a lot of new voices.
      - You can have the ROM of the game and the other SCC for Voice SET in the same slot expander.
      - You can insert the other SCC "in hot" in the INI screen and it'll be detected.
      - Compatible with the **double SCC** mode in [Flashjacks](http://www.acuariotuning.com/flashjacks)
  
  - DrumFIX by **WYZ**
  - Enables the *TURBOCPU* in PANASONIC TR & 2+
  - In pause mode -> extra options:
      - F2 key: In pause-> change player ship GFX
      - F3 key: In pause-> change gameplay speed
      - F4 key: In pause-> change Invincible mode
      
  - [Joymega](http://frs.badcoffee.info/hardware/joymega-en.html) support:
      - START button: Pause
      - A button: Continue, extend game
      - X button: In pause-> change player ship GFX
      - Y button: In pause-> change gameplay speed
      - Z button: In pause-> change Invincible mode
  
  - Selectable at boot: Language, VDP freq., invincible...
  - A lot of routines have been optimized.
  



Issues: **NOT** compatible with [Game Master](https://en.wikipedia.org/wiki/Konami_Game_Master). Now the game works in IM2 mode...

Note: I'ld like to include a retranslation created by "*232 translations*"... but, in this game, all the texts are stored as
compresed graphics... so... it'ld be really difficult to be implemented... Sorry... 


Thanks to: David Madurga,Toni Galvez, WYZ, FRS, FX and Vampier... and more and more people...
