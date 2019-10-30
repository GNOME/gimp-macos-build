#!/bin/sh
cd create-dmg

./create-dmg \
--volname "GIMP 2.10 Installer" \
--volicon "/Applications/GIMP-2.10.app/Contents/Resources/gimp.icns" \
--background "../gimp-dmg.png" \
--window-pos 1 1 \
--icon "GIMP-2.10.app" 190 360 \
--window-size 640 480 \
--icon-size 110 \
--icon "Applications" 110 110 \
--hide-extension "Applications" \
--app-drop-link 450 360 \
--format UDBZ \
"../test.dmg" \
"/Applications/GIMP-2.10.app"
cd ..