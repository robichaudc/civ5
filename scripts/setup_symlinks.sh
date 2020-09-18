#set -x

mac=true
if [[ $mac ]]; then
  echo "mac"
  SAVE_DIR=~/"Library/Application Support/Sid Meier's Civilization 5/Saves/single/quick"
else
  echo "linux"
  exit 1
  SAVE_DIR=~/".local/share/Aspyr/Sid Meier's Civilization 5/Saves/single/quick"
fi

cd ..
REPO_DIR=`pwd`

cd "$SAVE_DIR"
echo "Save dir"
ls
mv QuickSave.Civ5Save QuickSave.Civ5Save.old
ln -s $REPO_DIR/saves/QuickSave.Civ5Save


# TODO: Which config files need to be symlinked?
