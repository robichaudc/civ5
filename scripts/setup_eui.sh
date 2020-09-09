# Relative paths are relative to this script path, not the terminal working directory
cd $(dirname $0)

# TODO: Convert all files to lowercase? See step 7 in readme
# unzip with LL flag: unzip -LL EUI_zip_file.zip


# Steam install dir - note that spaces could be problematic
DLC_DIR=~/".steam/steam/steamapps/common/Sid Meier's Civilization V/steamassets/assets/dlc"
TEXT_DIR=~/".local/share/Aspyr/Sid Meier's Civilization 5/Text"
EUI_DIR="`pwd`/../eui/v1.29beta50"

# Remove old DLC version
cd "$DLC_DIR"

case "$1" in
  "remove")
    echo "Found remove"
    rm -rf ui_bc1 # Linux is lowercase
    cd "$TEXT_DIR"
    rm -f eui_text_*.xml csl_text_*.xml
    ;;
  "install")
    rm -rf ui_bc1 # Linux is lowercase
    cp -R $EUI_DIR/ui_bc1 .

    # Remove problematic modules
    cd ui_bc1
    rm -rf toppanel
    #rm -rf techtree
    #rm -rf tooltips
    rm -rf unitpanel

    #rm eui_?.civ5pkg

    cd "$TEXT_DIR"
    rm -f eui_text_*.xml csl_text_*.xml
    cp $EUI_DIR/*_text_*.xml .

    echo "EUI files:"
    ls "${DLC_DIR}/ui_bc1"
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
