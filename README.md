# Build GIMP/macOS inside CircleCI

This repository contains files related to GIMP/macOS build using CircleCI and some tips that
could help with local development as well.

## Build process description

To build GIMP/macOS we are using this repo, which contains a fork of relevant parts
of the [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx) project (`gimp` branch).
Fork adds modules related to GIMP and some gimp-specific patches to GTK.
Currently build is done using CircleCI.

Because CircleCI is not supporting gitlab [yet] there is a [GitHub
mirror](https://github.com/GNOME/gimp-macos-build) of this repository.
To get access to the Circle-CI build administration, packagers need to
ask admin access to this Github repository.

## Before you start

The GTK and GIMP build processes on macOS are very fragile. If you have any other build system (brew, MacPorts) installed – the local build instructions provide some support (taking `Homebrew` off `PATH`. Try to remove or isolate them from the JHBuild environment as much as you can.

The main reason for this: everything that Gimp needs must be packaged in the executable bundle or be part
of the MacOS SDK that is being called.

Some people were able to get working builds in the VirtualBox VM, others in a VMWare Fusion VM. Another approach could
be to create a separate user on your Mac.

In any case, the build process on Circle CI or the local version (see below) sets up most things from scratch.

## Prerequisites for local build (Draft) ##

At a minimum, you will need to install:

- XCode Command Line Tools
- [Rust](https://www.rust-lang.org/tools/install) (don't use `Homebrew` or `MacPorts`).

## Steps in the CircleCI [config.yml](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/blob/master/.circleci/config.yml) are:

- Install Python 3 (Rust is pre-installed) as they are required for the GIMP dependencies.
- Set up macOS 10.12 SDK. This is needed to ensure that GIMP can run on macOS 10.12+. See [this article](https://smallhacks.wordpress.com/2018/11/11/how-to-support-old-osx-version-with-a-recent-xcode/) for the details.
- Set up JHBuild with a custom `~/.config/jhbuildrc-custom` file (see https://github.com/GNOME/gimp-macos-build/blob/master/jhbuildrc-gtk-osx-gimp-2.99). As part of the setup, it is running `bootstrap-gtk-osx-gimp` JHBuild command to compile required modules to run JHBuild. JHBuild is using Python3 venv to run.
- Install [fork of the gtk-mac-bundler](https://github.com/lukaso/gtk-mac-bundler) - the tool which helps to create macOS application bundles for the GTK apps. This will hopefully shift to official [gtk-mac-bundler](https://github.com/GNOME/gtk-mac-bundler)
- Install all gtk-osx, gimp and WebKit dependencies using JHBuild
- Build WebKit v1. This step could be avoided as it takes a lot of time, this is a soft dependency.
- Build GIMP and gimp-help (from git).
- Import signing certificate/key from the environment variables
- Launch `build99.sh` which does (among other things):
  - Build package using `gtk-mac-bundler`
  - Use `install_name_tool` to fix all library paths to make package relocatable.
  - generate debug symbols
  - fix `pixmap` and `imm` cache files to remove absolute pathnames
  - compile all `.py` files to `.pyc` to avoid writes to the Application folder
  - fix `.gir` and `.typelib` library paths to make package relocatable
  - copy in icons
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

- `master`: latest GIMP release and build
- `gimp-2-10`: latest GIMP 2.10 release and build

## How to build locally (quick and dirty and might not work) ##

For a script that builds locally, a quick and dirty way to get all the commands is to run:

`brew install yq`

(remember that you are using `homebrew` here which won't be availabe during build time)

and then

```sh
git clone https://gitlab.gnome.org/Infrastructure/gimp-macos-build.git project
cd project
```

Then get the branch for the build you want to create a script for.

For 2.99:

```sh
git checkout master
```

Or for 2.10.28 (although there are tags for specific releases so go to that if desired)

```sh
git checkout gimp-2-10
```

Then

```sh
yq e '.jobs.[].steps[].run.command | select(length!=0)' .circleci/config.yml > ~/build_gimp.sh
cd ~
chmod +x build_gimp.sh
```

**Important** Now review the `build_gimp.sh` script and make sure you are comfortable with all
the commands. And as you go, you may want to comment things out. For example, the code signing
and notarization commands are not necessary. To understand the context, you can look at
`.circleci/config.yml` and see what the parts are for.

To run it of course:

`./build_gimp.sh`

## Debug info ##

By default, the executable will be built with debug symbols but optimizations, which make
debugging difficult. If you would like unoptimized code to be able to use the `lldb`
debugger to go through step by step, set:

```
$ export GIMP_DEBUG="true"
```

or if you followed the above local build instructions

```
GIMP_DEBUG="true" ./build_gimp.sh
```

## Appendix ##

The build used to depend on this [fork](https://gitlab.gnome.org/samm-git/gtk-osx/tree/gimp) of
[gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx) project (`gimp` branch).
