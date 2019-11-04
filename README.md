# Build GIMP/OSX inside CircleCI

This repository contains files related to GIMP/OSX build using CircleCI.

## Build process description

To build GIMP/MacOS we are using [fork](https://gitlab.gnome.org/samm-git/gtk-osx/tree/fork-test)
of the [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx) project. Fork adds modules related to GIMP
and some gimp-specific patches to GTK. Currently build is done using CircleCI.

Because CircleCI is not supporting gitlab [yet] there is a [GitHub mirror](https://github.com/GNOME/gimp-macos-build) of this repository.

## Before you starting

I found that GTK and GIMP builds on OSX are very fragile. If you have any other build system (brew, macports) installed - try to remove it first or at least isolate from jhbuild env as much as you can.

I was able to get working builds in the VirtualBox VM, it works stable enough for me.

## Steps in the [CircleCI config.yml](https://github.com/GNOME/gimp-macos-build/blob/master/.circleci/config.yml) are:

- Install gfortran and rust as they are required for the GIMP dependencies.
- Setup OSX 10.9 SDK. This is needed to ensure that GIMP is able to run on MacOS 10.9+. See [this article](https://smallhacks.wordpress.com/2018/11/11/how-to-support-old-osx-version-with-a-recent-xcode/) for the details.
- Setting up jhbuild with a custom `~/.config/jhbuildrc-custom` file (see https://github.com/GNOME/gimp-macos-build/blob/master/jhbuildrc-gtk-osx-gimp). As part of setup it is running `bootstrap-gtk-osx-gimp` jhbuild command to compile required modules to run jhbuild. Jhbuild is using Python3 venv to run.
- Install [fork of the gtk-mac-bundler](https://github.com/samm-git/gtk-mac-bundler/tree/fix-otool) - tool which helps to create MacOS application bundles for the GTK apps. Only difference with official one is [this PR](https://github.com/jralls/gtk-mac-bundler/pull/10)
- Installing all gtk-osx, gimp and WebKit dependencies using jhbuild
- Building WebKit v1. This step could be avoided as it takes a lot of time, this is a soft dependency.
- Building GIMP and gimp-help (from git).
- Importing signing certificate/key from the environment variables
- Launching `build.sh` which:
  - Building package using `gtk-mac-bundler`
  - Using `install_name_tool` fixing all library path to make package relocatable.
  - generating debug symbols
  - fixing pixmap and imm cache files to remove absolute pathnames
  - compiles all py files to pyc to avoid writes to the Application folders
  - Signing all binaries
  - Creating DMG package using [create-dmg](https://github.com/andreyvit/create-dmg) tool and signing it
- Uploading DMG to the CircleCI build artifacts

## Known bugs and limitations (merge requests are welcome!)

- [XPM import/export will not work](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/issues/6) due to missing libxpm.
- No scanning support. Scanner support needs to be re-implemented using ImageCaptureCore
framework. Probably could be a small Python plugin as [there is a module](https://pypi.org/project/pyobjc-framework-ImageCaptureCore/) for it.
- Some of the system modifiers are not working correctly, e.g. `Command+H`, `Command+~`, etc.
- Loading of the remote HTTP objects is not supported due to Glib limitations on macOS

## Branches

- `master`: latest GIMP release
- `gimp-2-10`: gimp-2-10 build
- `debug`: same as master, but with full debug symbols
- `hardened-runtime`: singed and notarized package with a hardened runtime enabled
