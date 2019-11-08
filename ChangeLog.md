## macOS specific changes

### not released yet

- Dependency updates: openjpeg, gexiv2, python2, lcms2, libtiff
- Enable matting levin engine support using macOS `Accelerate` framework and SuiteSparse
- LibHEIF updated to 1.6 to fix crash on save
- Performance improvements in LibHEIF save due to enabled ASM in x265

### gimp-2.10.14-x86_64.dmg

- macOS Catalina compatibility
- DMG opens folder with installer shortcut
- Build is notarised (without hardened runtime so far)
