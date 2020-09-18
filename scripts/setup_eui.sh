# Relative paths are relative to this script path, not the terminal working directory
cd $(dirname $0)

# Steam install dir - note that spaces could be problematic
DLC_DIR=~/".steam/steam/steamapps/common/Sid Meier's Civilization V/steamassets/assets/dlc"
DLC_EUI="$DLC_DIR/ui_bc1"
TEXT_DIR=~/".local/share/Aspyr/Sid Meier's Civilization 5/Text"
EUI_SRC="`pwd`/../eui/v1.29beta50"

EUI_FILES=""

cp_eui()
{
  cp -R $EUI_SRC/ui_bc1/$1 "$DLC_EUI"
}

### MAIN ###





case "$1" in

  "remove")
    echo "Removing EUI"
    cd "$DLC_DIR"
    rm -rf ui_bc1 # Linux is lowercase
    cd "$TEXT_DIR"
    rm -f eui_text_*.xml csl_text_*.xml
    ;;

  "install")
    rm -rf "$DLC_EUI"
    mkdir "$DLC_EUI"
    #cp -R $EUI_SRC/ui_bc1 .
    cp_eui "*"

    # Remove problematic modules
    #rm -rf toppanel
    #rm -rf techtree
    #rm -rf tooltips
    #rm -rf unitpanel

    echo "EUI files:"
    ls "$DLC_EUI"

    cd "$TEXT_DIR"
    rm -f eui_text_*.xml csl_text_*.xml
    cp $EUI_SRC/*_text_*.xml .
    ;;

  "debug")
    echo "Collect debug logs"
    journalctl | grep Civ5XP | tail
    ;;

  *)
    echo "Missing required arg"
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
