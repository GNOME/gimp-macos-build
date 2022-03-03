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

## Before you starting

I found that GTK and GIMP build process on macOS are very fragile. If you have any other build system (brew, MacPorts) installed - try to remove it first or at least isolate from the JHBuild environment as much as you can.

I was able to get working builds in the VirtualBox VM, it works stable enough for me.

## Steps in the CircleCI [config.yml](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/blob/master/.circleci/config.yml) are:

- Installs Python 3 and Rust as they are required for the GIMP dependencies.
- Setting up macOS 10.9 SDK. This is needed to ensure that GIMP can run on macOS 10.9+. See [this article](https://smallhacks.wordpress.com/2018/11/11/how-to-support-old-osx-version-with-a-recent-xcode/) for the details.
- Setting up JHBuild with a custom `~/.config/jhbuildrc-custom` file (see https://github.com/GNOME/gimp-macos-build/blob/master/jhbuildrc-gtk-osx-gimp). As part of the setup, it is running `bootstrap-gtk-osx-gimp` JHBuild command to compile required modules to run JHBuild. JHBuild is using Python3 venv to run.
- Installs [fork of the gtk-mac-bundler](https://github.com/samm-git/gtk-mac-bundler/tree/fix-otool) - the tool which helps to create macOS application bundles for the GTK apps. The only difference with official one is [this PR](https://github.com/jralls/gtk-mac-bundler/pull/10)
- Installing all gtk-osx, gimp and WebKit dependencies using JHBuild
- Building WebKit v1. This step could be avoided as it takes a lot of time, this is a soft dependency.
- Building GIMP and gimp-help (from git).
- Importing signing certificate/key from the environment variables
- Launching `build.sh` which:
  - Building package using `gtk-mac-bundler`
  - Using `install_name_tool` fixing all library path to make package relocatable.
  - generating debug symbols
  - fixing `pixmap` and `imm` cache files to remove absolute pathnames
  - compiles all `.py` files to `.pyc` to avoid writes to the Application folder
  - Signing all binaries
  - Creating a DMG package using [create-dmg](https://github.com/andreyvit/create-dmg) tool and signing it
- Notarizing package using Apple `altool` utility
- Uploading a DMG to the CircleCI build artifacts

## Managing the Circle CI build ##

The Circle CI build and its interaction with JHBuild create some specific issues that a packager needs to be aware of.

### Circle CI Issues that have been worked around ###

#### Build timelimit ####

Build jobs have a strict time limit of 1 hour. As soon as a job takes longer, it is canceled.

Due to this, and the fact that the build as a whole takes much more than an hour, creative measures
have had to be taken.

**Note** Additionally, There is a hard limit on the length of a single build step. If a step takes longer than an hour it simply
can't be build in Circle CI. For this reason, support for Webkit has had to be dropped.

#### JHBuild not detecting changes ####

Because of JHBuild's architecture, certain changes to packages it is building, are not detected at build time. This means that the build can become out of date and a full cache-break build will have to be undertaken.

Examples of things that JHBuild does not detect:

- A new patch file being added or removed (they are stored in directory `patches`)
- Changes to environment variables (such a `CFLAGS`) (are typically declared in `.circleci/config.yml`)
- Changes to the build command (set out in `.circleci/config.yml`)

Examples of things that JHBuild does detect:

- A new URL/version of a package
- New commits on a git based repo
- Changes in a dependency

### Fixes for these problems ###

In order to fix the above problems, the following has been done:

- **Timeouts** The build has been split into multiple jobs, each of which can take up to an hour.
  Before each job the build environment is stood up. Additionally the cache is loaded to provide
  the results of the previous jobs (build steps) as well as previous builds. This takes about 5 minutes
  to set up for each job.
- **JHBuild cannot detect certain changes** The full cache is broken by changing the first part of the
  cache key [see below for caching principles] whenever a change to the patch files (`patches` directory)
  occurs. This is done automatically.
- **cache is not updated when changes to build occur** Even though JHBuild detects the build change,
  the CircleCI caching mechanism needs to be alerted to save an update version of the cache. This is
  done whenever a change to `modulesets` or `.circleci/config.yml` occurs. It is done by changing the
  last part of the cache key. This is done automatically.

**Note** These changes only relate to the build steps, not to setting up the build environment. If
changes are required, the cache keys will have to be modified for the build step, manually.

### Caching to get around build timelimit ###

In order to speed up builds, and to be able to pass intermediate artifacts between build jobs, the
results of each job is cached. This uses CircleCI's caching mechanism.

The following are aspects of the caching:

- The JHBuild cache and the rest of the build cache are managed separately
- The cache is only saved when a new cache key is used, so by default, nothing new that happens in a build
  is saved until the cache key is changed
- They keys are arranged in an onion shape. Meaning the most specific cache is hit first, but with the broadest
  number of items cached. This means the full build up to and including Gimp. Narrower keys don't include Gimp,
  then Gegl/Babl, then Dependencies Part 2, then dependencies Part 1, and so on. This is required to pass
  intermediate artifacts between steps of the build.
- The keys for reloading the cache are tested and loaded in order. Each key is tested, and if found, loaded. If it is not found, the algorithm goes to the next key. Circleci then drops the suffix (after the '-') and tries to load those keys (if they are listed in the keys)
- When new information is layered onto the cache, the tail end of the cache keys should be iterated. So `break5-gimpv3-cacheiter7` should be changed to `break5-gimpv3-cacheiter8`. This will keep using the cache, but allow new changes to be saved. (Done automatically.)
- When the build has to be redone from scratch, because a dependency has changed, then the first part of the cache key changes. This then means no cache is found and everything goes from scratch. Here the key goes from `break5-gimpv3-cacheiter7` to `break6-gimpv3-cacheiter1` (the `break` part matters, the `cacheiter` part doesn't). Done automatically.

## Other related links

 - [Gtk-OSX](https://gitlab.gnome.org/GNOME/gtk-osx/) project to simplify building MacOS application bundles for Gtk+-based applications
 - [gimp-plugins-collection](https://github.com/aferrero2707/gimp-plugins-collection) -  	GMIC, LiquidRescale, NUFraw, PhFGimp and ResynthesizerPlugin GIMP plugin builds, including macOS version
 - CircleCI [gimp-macos-build project](https://circleci.com/gh/GNOME/gimp-macos-build)
 - How this repo uses [JHBuild and Gtk-OSX](README_JHBUILD_GTK_OSX.md)

## Known bugs and limitations (merge requests are welcome!)

- [XPM import/export will not work](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/issues/6) due to missing libXpm/macOS.
- No scanning support. Scanner support needs to be re-implemented using ImageCaptureCore
framework. Probably could be a small Python plugin as [there is a module](https://pypi.org/project/pyobjc-framework-ImageCaptureCore/) for it. As a workaround you can use your scanner utility or any other third-party tool.
- Some of the system modifiers are not working correctly, e.g. `Command+H`, `Command+~`, etc.
- Loading of the remote HTTP objects is not supported due to [Glib limitations on macOS](https://gitlab.gnome.org/GNOME/glib/issues/1579)

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

## Swap local build ##

A tool to swap local builds is available. This allows local devs to have multiple versions
of gimp running at the same time.

This tool can be called at the top of a local build file using:

```
project/swap-local-build.sh --gimp210
```

or

```
project/swap-local-build.sh --gimp299
```

Other options are available. This tool will only be available once the setup script has been
run once as it is within the `project` directory.

