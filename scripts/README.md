The files in this folder are used to build Gimp both locally and on
Circle CI.

- Look at `.circleci/config.yml` for how it is built on 
Circle CI.
- To build locally, run

```sh
macports0_install.sh
macports1_install_packages.sh
macports2_install_gimp.sh
macports3_build_app.sh
macports3_build_dmg.sh
```

If you need to start over from scratch, run:

```sh
macports_uninstall.sh
```

`macports4_build_dmg.sh` can fail because it needs to give permissions
to access Finder in order to layout the DMG installer. However it should
pop up a permissions dialog. Click Allow/OK and it sould be fine.

## Quick rebuild ##

If you want to build and test locally, once you've used the scripts abovec, for a local build loop use the following scripts:

```sh
open_gimp.sh # Open Gimp in VS Code in the directory where the source is
quick_build.sh # Build Gimp from that directory after having made code changes
```

```sh
VGIMP=2
```

A runnable gimp will be built into the macports bin directory (e.g. `~/macports-gimp${VGIMP}-arm64/bin`).

To `cd` to the gimp directory, run:

```sh
. cd_gimp.sh
```

## Notarization and security ##

These links have content around code signing and security entitlements.
When these weren't set correctly, the application, and specifically
Python plug-ins failed to load and basically hung. There were no error
messages, so it was difficult to figure out what was going wrong.

- [https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_allow-unsigned-executable-memory](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_allow-unsigned-executable-memory)
- [https://developer.apple.com/documentation/apple-silicon/porting-just-in-time-compilers-to-apple-silicon](https://developer.apple.com/documentation/apple-silicon/porting-just-in-time-compilers-to-apple-silicon)
- [https://developer.apple.com/forums/thread/132908](https://developer.apple.com/forums/thread/132908)
- [https://developer.apple.com/forums/thread/130560](https://developer.apple.com/forums/thread/130560)
