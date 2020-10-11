# Relative paths are relative to this script path, not the terminal working directory
cd $(dirname $0)

mac=true # TODO

case "`uname`" in
  (*Linux*)
    echo "linux detected"
    # Steam install dir - note that spaces could be problematic
    DLC_DIR=~/".steam/steam/steamapps/common/Sid Meier's Civilization V/steamassets/assets/dlc"
    TEXT_DIR=~/".local/share/Aspyr/Sid Meier's Civilization 5/Text"
    DLC_EUI="$DLC_DIR/ui_bc1"
    EUI_SRC="`pwd`/../eui/v1.29beta50"
  ;;
  (*Darwin*) # Mac
    echo "mac detected"
    #/Users/A155793/Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V
    # Civilization V.app/Contents/Home/assets/DLC
    DLC_DIR=~/"Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app/Contents/Assets/Assets/DLC"
    TEXT_DIR=~/"Library/Application Support/Sid Meier's Civilization 5/Text"
    DLC_EUI="$DLC_DIR/UI_bc1"
    EUI_SRC="`pwd`/../eui/EUI_v1.29beta50_mac"
    ;;
    (*CYGWIN*) openCmd='cygstart'; ;;
    (*) echo 'error: unsupported platform.'; exit 2;
  ;;
  (*)
    echo "OS not recognized"
    exit 1
  ;;
esac

#if [[ $mac ]]; then
#else
#fi





#EUI_FILES=""

cp_eui_dlc()
{
  echo "Copying EUI DLC files:"
  cp -R "$EUI_SRC/ui_bc1/" "$DLC_EUI"
  ls "$DLC_EUI"
  echo
}

cp_eui_text()
{
  echo "Copying EUI text xml files:"
  cd "$TEXT_DIR"
  cp $EUI_SRC/*_text_*.xml .
  # TODO: Proper case
  ls "$TEXT_DIR"
  echo
}

rm_eui()
{
  echo "Removing EUI DLC:"
  #cd "$DLC_DIR"
  #echo "dlc before"
  #ls "$DLC_EUI"
  rm -rf "$DLC_EUI" # Linux is lowercase
  #ls "$DLC_EUI"

  echo "Removing EUI text xml:"
  cd "$TEXT_DIR"
  rm -f eui_text_*.xml csl_text_*.xml EUI_text_*
  #ls
  #;;

  # Capitalize for mac?
}

### MAIN ###
case "$1" in

  "remove")
    rm_eui
    #echo "Removing EUI"
    #cd "$DLC_DIR"
    #rm -rf ui_bc1 UI_bc1 # Linux is lowercase
    #cd "$TEXT_DIR"
    #rm -f eui_text_*.xml csl_text_*.xml
    ;;

  "install")
    rm_eui
    #rm -rf "$DLC_EUI"
    # mkdir "$DLC_EUI"
    #cp -R $EUI_SRC/ui_bc1 .
    cp_eui_dlc #"*"
    cp_eui_text

    # Remove problematic modules
    #rm -rf toppanel
    #rm -rf techtree
    #rm -rf tooltips
    #rm -rf unitpanel

    #rm -f eui_text_*.xml csl_text_*.xml
    #cp $EUI_SRC/*_text_*.xml .
    ;;

  "debug")
    echo "Collect debug logs"
    journalctl | grep Civ5XP | tail
    ;;

  *)
    echo "Missing required argument: [install, remove, debug]"
    exit 1;;
esac

# Modular removal
# Seems easier to use terminal over file explorer
# Don't remove art* or core directories

# Turn 239->40
# Attempt 1: rm -rf d* f* i* l* o* p* . # Crash

# Attempt 2: rm -rf actioninfopanel/ city* t* u* y* . # No crash

# Attempt 4: rm -rf actioninfopanel/ city* . # Crash

# Attempt 5: rm -rf t* # No crash

# Attempt 6: rm -rf techtree # Crash

# Attempt 7: rm -rf toppanel # No crash!

# Turn 240->241
# rm -rf t* # No crash!
