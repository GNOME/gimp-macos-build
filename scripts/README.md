The files in this folder are used to build Gimp both locally and on
Circle CI.

- Look at `.circleci/config.yml` for how it is built on 
Circle CI.
- To build locally, run

```sh
macports0_install.sh
macports1_install_packages.sh
macports2_install_gimp.sh
macporst3_build_dmg.sh
```

If you need to start over from scratch, run:

```sh
macports_uninstall.sh
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
