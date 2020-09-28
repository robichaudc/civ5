# civ5

## Work MBP Todo
- Enable save-before and save-after end-of-turn


---

# Logging
- Use `journalctl | grep Civ5XP`
- Example error message: "Sep 08 22:47:05 bigred kernel: Civ5XP[414771]: segfault at 669d2604 ip 00000000dccece08 sp 00000000ec4fecdc error 4 in libCvGameCoreDLL_Expansion2.so[dc97e000+55f000]"
---

## Config
config.ini
- I already have changes, diff against the default

Should I add EUI files, or a simple add/ remove script?

Am I using DX9 or 11? Or none at all?

What else can we turn off? Reward popups?
Look into mapping from game screen and help understanding the mapping


# Potential fixes / next steps
- Need better EUI logging, so we can isolate the issue that is causing the crash
- Crash logs: Research issue that shows in logs - ?
- "There have been anecdotal reports of Mac users having success using Windows virtualization with e.g. Parallels or VirtualBox."

  Try Linux + Wine

  Try Linux solutions: Steam proto…, ludity

- How to determine root cause?
	- Need a reproducible crash, can test it on all the machines (MBP x2, big-red)
	- How to find crash logs?
	- Look into EUI, can it be updated? Easier install, logging
	- Try turning down all graphics settings, removing all or part of EUI, disable animations (great people)
- Check civ5 reddit, sidebar links
- Check this thread - https://www.reddit.com/r/civ5/comments/ej3q3g/eui_crashes_on_mac_mojave/ Use legacy version of EUI maybe
	- https://www.reddit.com/r/civ5/comments/e43gcm/constant_crashing_on_mac/
	- Partition solution - https://www.reddit.com/r/civ5/comments/7gzx00/civ_5_is_crashing_on_my_mac_pro_help/
	- Catalina megathread - https://www.reddit.com/r/civ5/comments/dy6uzd/macos_catalina_megathread/
- https://www.reddit.com/r/linux_gaming/comments/2zd6xh/civ5_for_linux_not_working/

  Set "Low Leader scene quality”

  Linux system - Check into updated drivers for linux box + video card and others

  Could have 2 separate installs, one with EUI and one without, to see if that makes a difference

  Try DirectX 11 (Windows)



# Attempted fixes
- Lowered to a single CPU
  - Seems like hyperthreading was disabled here
- Changing max simluataneious threads in config.ini
 - Tried increasing and decreasing, no effect


# Crash situations
- Using a work boat
- Using a great person



# Other tasks
- Message civfanatics and see if bc1 is interested in open source collaboration?
- Is there a way I can enable more useful logging?

---

# Update linux big-red
- Try out fixes suggested in reddit / steam forums
  - Try out removing EUI (via script) and confirm it is removed and if crash is still happening
  - LD_PRELOAD
  - taskset
