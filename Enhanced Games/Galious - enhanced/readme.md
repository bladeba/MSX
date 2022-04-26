**The Maze of Galious Enhanced Version 1.02**

only for MSX 2 or higher (with 128 Kbytes of VRAM)
##

Some screenshoots comparing original and enhanced versions:

<img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/Title MSX 1.png" alt="1" width="400"/> <img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/Title MSX2.png" alt="1" width="400"/> 

<img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/ROOM 01 MSX1.png" alt="1" width="400"/> <img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/ROOM 01 MSX 2.png" alt="1" width="400"/> 

<img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/ROOM 8F MSX1.png" alt="1" width="400"/> <img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/ROOM 8F MSX 2.png" alt="1" width="400"/> 

<img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/BOSS 1 MSX 1.png" alt="2" width="400"/> <img src="https://raw.githubusercontent.com/bladeba/MSX/master/media//Galious Enhanced screenshoots/BOSS 1 MSX 2.png" alt="3" width="400"/> 


##
[Video demostration](https://www.youtube.com/watch?v=1EtElmheaek)

##

Credits:
- Programmed by Victor Martinez & David Madurga
- New graphics and colours by [Toni Galvez](https://twitter.com/TonimanGalvez)
- SCC music by [Jan van Valburg](https://www.msx.org/users/janvv)
- Original TURBO FIX Routine and Joymega routines by [FRS](http://frs.badcoffee.info/)
- Voice Set by WYZ/ARTRAG/[TODOJINGLES](https://todojingles.com/)
- Retranslation by [232 translations](http://www.msxtranslations.com/translations.php)


##

Changelog:

   
   **V 1.02** :    
   
               - Fixed: When there is a special item in that room and you die, then after the item doesn´t apear correctly.
   
               - Fixed: Sometimes the *World X* or *Castle* texts in scoreboard don't show correctly.
   
   **V 1.01** :   
   
               - Fixed: some texts.

              
##

For IPS Patch use this original ROM: 

**SHA-1**
4d51d3c5036311392b173a576bc7d91dc9fed6cb	


Finally you will obtain a ROM with a size of 512 Kbytes and **KONAMI SCC Mapper**


* If you want to play it in [webMSX](http://webmsx.org/) put in the name of the ROM [KonamiSCC]

example:Galious[KonamiSCC].ROM     

##

Issues: Not compatible with Game Master

##
Notes:
  
  - You can edit the ROM after patched with this:
  - 
      ------------------------------------------------------------------
      Values forced in ROM at BOOT. Position: 0019h (0025d) Edit with an HEX editor after patch...
      
       - forced_Double_PSG_in_ROM:          db  0 ;0=Check available, 1=Forced Available
       - forced_continue_available_in_ROM:  db  0 ;0=no, 1=Yes
       - forced_language_in_ROM:            db  0 ;0=Default BIOS, 1=Japanese, 2=English, 3=Spanish

  - For emulation, use [openMSX](https://openmsx.org/) or [webMSX](http://webmsx.org/)... or some effects won´t work correctly.
  - The gameplay is exactly the same as the original game (but smoother...)
  - Now the game is in screen 5 mode. All graphics were remade.
  - Hold **TAB** to throttle the game speed (by FRS)
  - In **Item Menu** press CTRL to toggle descriptions (weapons or items)
  - For the VOICE SET, you don't need a second SCC.
  - There is a special way to listen all the musics... I hope you can find it.... ;-)
  

##
Thanks to:

  - Fernando Garcia: He helped us with the "*fast music replayer*" and "*BOSS movement*" routines... You're a super programmer!! Thanks for all!!
  - FRS: thanks for allow me to use your Turbo FIX routine... I love it!!
  - WYZ: thanks for all your help and trust
  - [Toni Galvez](https://twitter.com/TonimanGalvez): you're an artist!! Thanks for your cooperation
  - [NataliaPC](https://twitter.com/ishwin74): Thanks for yor plugin to convert to MSX images for [Aseprite](https://community.aseprite.org/t/extension-msx-image-file-import/8655)
  - the beta testers... Thanks!!
  - and the "vintage KONAMI Team"!!
##
If you like my job you can show your
appreciation by donating any amount to my
**PayPal** account: [bladeba1977@gmail.com](https://paypal.me/bladeba1977)
