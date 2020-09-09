set -x
SAVE_DIR=~/".local/share/Aspyr/Sid Meier's Civilization 5/Saves/single/quick"
cd ..
REPO_DIR=`pwd`

cd "$SAVE_DIR"
mv QuickSave.Civ5Save QuickSave.Civ5Save.old
ln -s $REPO_DIR/saves/QuickSave.Civ5Save


# TODO: Which config files need to be symlinked?
