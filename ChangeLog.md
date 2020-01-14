## macOS specific changes

### not released yet

- Fix Print Preview dialog on the recent macOS versions (GTK issue)
- Fix `Cmd+H` system hotkey in the GIMP window and startup warning
- Dependency updates: openjpeg, gexiv2, python2, lcms2, libtiff, ghostscript, poppler, glib, libheif, pango
- Enable matting levin engine support using macOS `Accelerate` framework and SuiteSparse
- LibHEIF updated to 1.6 to fix crash on save
- Performance improvements in LibHEIF save due to enabled ASM in x265

### gimp-2.10.14-x86_64.dmg

- macOS Catalina compatibility
- DMG opens folder with installer shortcut
- Build is notarised (without hardened runtime so far)
