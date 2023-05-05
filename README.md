# Build GIMP/macOS inside CircleCI and MacStadium

| x86_64 Build Stats | arm64 Build Stats |
| ----------- | ----------- |
| <p align="center"><a href="https://app.circleci.com/insights/github/GNOME/gimp-macos-build/workflows/build-x86_64?branch=master"><img src="https://dl.circleci.com/insights-snapshot/gh/GNOME/gimp-macos-build/master/build-x86_64/badge.svg" alt="InsightsSnapshot" /></a></p> | <p align="center"><a href="https://dl.circleci.com/insights-snapshot/gh/GNOME/gimp-macos-build/master/build-arm64/badge.svg"><img src="https://dl.circleci.com/insights-snapshot/gh/GNOME/gimp-macos-build/master/build-arm64/badge.svg" alt="InsightsSnapshot" /></a></p> |

This repository contains files related to GIMP/macOS build using CircleCI and some tips that
could help with local development as well.

[![CircleCI](https://circleci.com/gh/GNOME/gimp-macos-build/tree/master.svg?style=svg)](https://circleci.com/gh/GNOME/gimp-macos-build/?branch=master)

## Build process description

To build GIMP/macOS we are using this repo.

Because CircleCI is not supporting gitlab [yet] there is a [GitHub
mirror](https://github.com/GNOME/gimp-macos-build) of this repository.
To get access to the Circle-CI build administration, packagers need to
ask for admin access to this Github repository.

Also, because CircleCI does not support arm64 builds (at this point we haven't ported to it), we are using MacStadium to build the arm64 builds.

## Building

See [scripts/README.md](scripts/README.md) for details on how to build locally and on CircleCI.

**Note**: CircleCI is currently set up to build the `master` and `gimp-2-10` branchs on a nightly basis (and pulls the latest GIMP code from the same branches on the [GIMP repo](https://gitlab.gnome.org/GNOME/gimp). It also builds any branch of this repo that is pushed to.

## Releases

For releases, create a release branch, and go into the `/ports/gimp` directory and edit the `Portfile` to update the version number and set the correct release tag (there are examples which are commented out). Then push the branch to this repo and CircleCI will build it.

When ready, the branch can be merged to `master` and the release can be tagged on this repo (use the same tag). That build will be the release build (in the Circle CI artifacts). There will be two builds, one for arm64 and one for x86_64.

Once everything is fine with the release, create a new branch for going back to building the head release. Update the version appropriately in the `Portfile` and set to pulling the `master` branch of the GIMP repo. Once this is working properly, merge the new branch back to `master`.

# Prerequisites for local build (Draft) ##

At a minimum, you will need to install:

- XCode Command Line Tools or XCode

## Steps in the CircleCI [config.yml](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/blob/master/.circleci/config.yml) are:

**NOTE** This section is out of date. Needs to be updated.

- Install Python 3 (Rust is pre-installed) as they are required for the GIMP dependencies.
- Set up macOS 10.12 SDK. This is needed to ensure that GIMP can run on macOS 10.12+. See [this article](https://smallhacks.wordpress.com/2018/11/11/how-to-support-old-osx-version-with-a-recent-xcode/) for the details.
- Set up JHBuild with a custom `~/.config/jhbuildrc-custom` file (see https://github.com/GNOME/gimp-macos-build/blob/master/jhbuildrc-gtk-osx-gimp). As part of the setup, it is running `bootstrap-gtk-osx-gimp` JHBuild command to compile required modules to run JHBuild. JHBuild is using Python3 venv to run.
- Install [fork of the gtk-mac-bundler](https://gitlab.gnome.org/lukaso/gtk-mac-bundler) - the tool which helps to create macOS application bundles for the GTK apps. This will hopefully shift to official [gtk-mac-bundler](https://github.com/GNOME/gtk-mac-bundler)
- Install all gtk-osx, gimp and WebKit dependencies using JHBuild
- Build GIMP.
- Import signing certificate/key from the environment variables
- Launch `macports_build.sh` which does (among other things):
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

## Managing the Circle CI build ##

The Circle CI build creates some specific issues that a packager needs to be aware of.

### Circle CI Issues that have been worked around ###

#### Build timelimit ####

Build jobs have a strict time limit of 3 hours. As soon as a job takes longer, it is canceled.

Due to this, and the fact that a full build takes much more than 3 hours, creative measures
have had to be taken.

#### Length of build ####

A full build (including all dependencies) takes more than 3 hours, meaning it is very
expensive to rebuild from scratch on every commit.

### Fixes for problems ###

In order to fix the above problems, the following has been done:

- **Timeouts** The build has been split into multiple jobs, each of which can take up to 3 hours.
  Before each job the build environment is stood up. Additionally the cache is loaded to provide
  the results of the previous jobs (build steps) as well as previous builds. This takes about 5 minutes
  to set up for each job.
- **Length of build** The full cache is broken by changing the first part of the
  cache key [see below for caching principles] whenever the file `./ports/cache_break` is changed.
  This will trigger a full build of everthing from scratch and will take north of 3 hours to complete.
  Recommended only in extreme circumstances.
- **caching** The cache is saved on every build step, due to the need for any changes to pass to
  the next build step. This can take from 5 to 30 minutes as the full cache weighs in at a
  whopping 6.8GB. This is way above the recommended limit of Circle CI but is unavoidable due to
  the build time limits.

### Caching to get around build timelimit ###

In order to speed up builds, and to be able to pass intermediate artifacts between build jobs, the
results of each job is cached. This uses CircleCI's caching mechanism.

The following are aspects of the caching:

- They keys are arranged in an onion shape. Meaning the most specific cache is hit first, but with the broadest
  number of items cached. This means the full build up to and including GiMP. Narrower keys don't include GIMP,
  then Dependencies Part 3, then Dependencies Part 2, then dependencies Part 1, and so on. This is required to pass
  intermediate artifacts between steps of the build.
- The keys for reloading the cache are tested and loaded in order. Each key is tested, and if found, loaded. If it is not found, the algorithm goes to the next key. Circleci then drops the suffix (after the '-') and tries to load those keys (if they are listed in the keys)
- The build script manages swapping out cache keys automatically. See `config.yml` for details.

## Other related links

 - [gimp-plugins-collection](https://github.com/aferrero2707/gimp-plugins-collection) - GMIC, LiquidRescale, NUFraw, PhFGimp and ResynthesizerPlugin GIMP plugin builds, including macOS version. If these are not signed
   they will need to be modified by removing the apple quarantine (and requires admin rights)
 - CircleCI [gimp-macos-build project](https://circleci.com/gh/GNOME/gimp-macos-build)
 - How this repo uses [JHBuild and Gtk-OSX](README_JHBUILD_GTK_OSX.md)

## Known bugs and limitations (merge requests are welcome!)

- [XPM import/export will not work](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/issues/6) due to missing libXpm/macOS.
- No scanning support. Scanner support needs to be re-implemented using ImageCaptureCore
framework. Probably could be a small Python plugin as [there is a module](https://pypi.org/project/pyobjc-framework-ImageCaptureCore/) for it. As a workaround you can use your scanner utility or any other third-party tool.
- Some of the system modifiers are not working correctly, e.g., `Command+H`, `Command+~`, etc.
- Loading of remote HTTP objects is not supported due to [Glib limitations on macOS](https://gitlab.gnome.org/GNOME/glib/issues/1579)

## Branches

- `master`: latest GIMP release and build (development)
- `gimp-2-10`: latest GIMP 2.10 release and build (stable)

## How to build locally (beta) ##

- See `./scripts/README.md`

Developing GIMP (or dependencies) locally still needs to be refined as the Macports
environment is not that amenable to that workflow.

### Apple Silicon (M1, arm64) Support ###

The local build script supports building on Apple Silicon on an M1/2 mac as well as Intel macs. The script
will autodetect the architecture and build accordingly.

Additionally, the x86_64 build will also work on Apple Silicon if built from a shell
running in Rosetta (for example by running `arch -x86_64 zsh`).

### Instructions ###

If you run into issues with Homebrew versions of libraries being used instead of macports versions, it's easier to retry with Homebrew disabled somehow. (Just take care your login shell isn't a Homebrew shell.)

From your `$HOME` directory:

```sh
git clone https://gitlab.gnome.org/Infrastructure/gimp-macos-build.git project
cd project
```

Then get the branch for the build you want to create a script for.

For 2.99.xx:

```sh
git checkout master
```

Or for 2.10.xx (although there are tags for specific releases so go to that if desired):

```sh
git checkout gimp-2-10
```

Then goto `/Users/Shared/` and checkout GIMP itself into `gimp-git`:

```sh
cd /Users/Shared/
sudo git clone https://gitlab.gnome.org/GNOME/gimp.git gimp-git
```

If building locally, get the branch for GIMP that matches the version you chose before:

```sh
cd gimp-git
git checkout master
```

Or you could be using a different branch, e.g. 2.10.xx:

```sh
cd gimp-git
git checkout gimp-2-10
```

Then follow instructions in `scripts/README.md`

The `Gimp` executable will be in:

```sh
/opt/local/bin/gimp
```

Additionally the script will create a staged version of the app in:

```sh
~/macports-gimp299-osx-app
```

or 

```sh
~/macports-gimp299-osx-app-x86_64
```

depending on architecture.

Which can be run with:

```sh
~/gimp299-osx-app/GIMP.app/Contents/MacOS/gimp
```

or

```sh
~/gimp299-osx-app-x86_64/GIMP.app/Contents/MacOS/gimp
```

Finally, the script will create a DMG file which is the "installer", in `/tmp/artifacts/`

## Debug info ##

By default, the executable will be built with debug symbols.

## Apple tools ##

There are a number of Apple tools that can help with debugging.

### Instruments ###

Instruments allows you to get profiling runs. The most interesting ones are the Time Profiler
and the Animation Hitches tool.

### XCode for debugging view hierarchies and the like ###

This How To works incredibly well for Gimp, even though it is written for Firefox.

https://firefox-source-docs.mozilla.org/contributing/debugging/debugging_on_macos.html

One change you need to make. In the scheme, add an "Argument Passed on Launch" and set it
to `--`.

### Memory Leaks ###

To get a memory leak report, you can use the `leaks` tool. It is part of the XCode command line tools.

Run the following commands to get a leaks report for GIMP (you can leave it running, just don't quit gimp before running the `leaks` command):
```sh
export MallocStackLogging=1
gimp
```

Do whatever you want to do in GIMP to create the leaks. Then, without quitting gimp, run the following command to get the leaks report:

```sh
leaks gimp > ~/Downloads/leaks-with-malloc-check.txt
```

This was pulled from https://developer.apple.com/library/archive/documentation/Performance/Conceptual/ManagingMemory/Articles/FindingLeaks.html

## Our partners ##

These companies generously support the development of GIMP on MacOS.

[CircleCI](https://circleci.com/)

![MacStadium](https://uploads-ssl.webflow.com/5ac3c046c82724970fc60918/5c019d917bba312af7553b49_MacStadium-developerlogo.png)
