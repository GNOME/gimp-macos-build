# Build GIMP/macOS inside CircleCI

This repository contains files related to GIMP/macOS build using CircleCI.

## Build process description

To build GIMP/macOS we are using [fork](https://gitlab.gnome.org/samm-git/gtk-osx/tree/gimp)
of the [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx) project (`gimp` branch). 
Fork adds modules related to GIMP and some gimp-specific patches to GTK.
Currently build is done using CircleCI.

Because CircleCI is not supporting gitlab [yet] there is a [GitHub
mirror](https://github.com/GNOME/gimp-macos-build) of this repository.
To get access to the Circle-CI build administration, packagers need to
ask admin access to this Github repository.

## Before you start

I found that the GTK and GIMP build processes on macOS are very fragile. If you have any other build system (brew, MacPorts) installed – try to remove it first or at least isolate from the JHBuild environment as much as you can.

I was able to get working builds in the VirtualBox VM, it works stable enough for me.

## Steps in the CircleCI [config.yml](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/blob/master/.circleci/config.yml) are:

- Install Python 3 and Rust as they are required for the GIMP dependencies.
- Set up macOS 10.9 SDK. This is needed to ensure that GIMP can run on macOS 10.9+. See [this article](https://smallhacks.wordpress.com/2018/11/11/how-to-support-old-osx-version-with-a-recent-xcode/) for the details.
- Set up JHBuild with a custom `~/.config/jhbuildrc-custom` file (see https://github.com/GNOME/gimp-macos-build/blob/master/jhbuildrc-gtk-osx-gimp). As part of the setup, it is running `bootstrap-gtk-osx-gimp` JHBuild command to compile required modules to run JHBuild. JHBuild is using Python3 venv to run.
- Install [fork of the gtk-mac-bundler](https://github.com/samm-git/gtk-mac-bundler/tree/fix-otool) - the tool which helps to create macOS application bundles for the GTK apps. The only difference with official one is [this PR](https://github.com/jralls/gtk-mac-bundler/pull/10)
- Install all gtk-osx, gimp and WebKit dependencies using JHBuild
- Build WebKit v1. This step could be avoided as it takes a lot of time, this is a soft dependency.
- Build GIMP and gimp-help (from git).
- Import signing certificate/key from the environment variables
- Launch `build.sh` which does:
  - Build package using `gtk-mac-bundler`
  - Use `install_name_tool` to fix all library paths to make package relocatable.
  - generate debug symbols
  - fix `pixmap` and `imm` cache files to remove absolute pathnames
  - compile all `.py` files to `.pyc` to avoid writes to the Application folder
  - Sign all binaries
  - Create a DMG package using [create-dmg](https://github.com/andreyvit/create-dmg) tool and sign it
- Notarize package using Apple `altool` utility
- Upload a DMG to the CircleCI build artifacts

## Other related links

 - [Gtk-OSX](https://gitlab.gnome.org/GNOME/gtk-osx/) project to simplify building MacOS application bundles for Gtk+-based applications
 - [gimp-plugins-collection](https://github.com/aferrero2707/gimp-plugins-collection) - GMIC, LiquidRescale, NUFraw, PhFGimp and ResynthesizerPlugin GIMP plugin builds, including macOS version
 - CircleCI [gimp-macos-build project](https://circleci.com/gh/GNOME/gimp-macos-build)

## Known bugs and limitations (merge requests are welcome!)

- [XPM import/export will not work](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/issues/6) due to missing libXpm/macOS.
- No scanning support. Scanner support needs to be re-implemented using ImageCaptureCore
framework. Probably could be a small Python plugin as [there is a module](https://pypi.org/project/pyobjc-framework-ImageCaptureCore/) for it. As a workaround you can use your scanner utility or any other third-party tool.
- Some of the system modifiers are not working correctly, e.g., `Command+H`, `Command+~`, etc.
- Loading of remote HTTP objects is not supported due to [Glib limitations on macOS](https://gitlab.gnome.org/GNOME/glib/issues/1579)

## Branches

- `master`: latest GIMP release
- `gimp-2-10`: gimp-2-10 build

## How to build locally (quick and dirty and might not work)

For a script that builds locally, a quick and dirty way to get all the commands is to run:

`brew install yq`

and then

```sh
git clone https://gitlab.gnome.org/Infrastructure/gimp-macos-build.git
cd gimp-macos-build
```

Then get the branch for the build you want to create a script for.

For 2.99:

```sh
git checkout master
```

Or for 2.10.28

```sh
git checkout gimp-2-10
```

Then

```sh
yq e '.jobs.[].steps[].run.command | select(length!=0)' .circleci/config.yml > ~/build_gimp.sh
cd ~
chmod +x build_gimp.sh
```

But then please please check the file and make sure you are comfortable with all the commands. And as you go, you may want to comment things out.

To run it of course:

`./build_gimp.sh`
