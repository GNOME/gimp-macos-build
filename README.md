# Build GIMP/macOS inside CircleCI and MacStadium

| x86_64 Build Stats | arm64 Build Stats |
| ----------- | ----------- |
| <p align="center"><a href="https://app.circleci.com/insights/github/GNOME/gimp-macos-build/workflows/build-x86_64?branch=master"><img src="https://dl.circleci.com/insights-snapshot/gh/GNOME/gimp-macos-build/master/build-x86_64/badge.svg" alt="InsightsSnapshot" /></a></p> | <p align="center"><a href="https://dl.circleci.com/insights-snapshot/gh/GNOME/gimp-macos-build/master/build-arm64/badge.svg"><img src="https://dl.circleci.com/insights-snapshot/gh/GNOME/gimp-macos-build/master/build-arm64/badge.svg" alt="InsightsSnapshot" /></a></p> |

This repository contains files related to GIMP/macOS build using CircleCI and MacStadium and some tips that could help with local development as well.

[![CircleCI](https://circleci.com/gh/GNOME/gimp-macos-build/tree/master.svg?style=svg)](https://circleci.com/gh/GNOME/gimp-macos-build/?branch=master)

## Build process description

To build GIMP/macOS we are using this repo.

CircleCI supports self-hosted gitlab however it doesn't yet work. Therefore there is a [GitHub mirror](https://github.com/GNOME/gimp-macos-build) of this repository. To get access to the CircleCI build administration, packagers need to ask for admin access to this Github repository. This will not provide all access but enough to manage all day to day issues. Anything further needs to be requested via an issue at https://gitlab.gnome.org/Infrastructure/Infrastructure/-/issues

Also, currently arm64 builds are built on a dedicated machine provided by MacStadium (due to CircleCI previously not supporting arm builds).

## Building

See the dedicated page on the developer site https://developer.gimp.org/core/setup/build/macos/
for details on how to build locally and on CircleCI.

* Developing GIMP (or dependencies) locally still needs to be refined as the Macports
environment is not that amenable to that workflow.

## MacPorts

Sometimes it is necessary to edit or patch a package in MacPorts. There are a few packages aside from GIMP that we have our own `Portfile` for. These are: `babl`, `gegl`, occasionally others as needed (breaking build, etc.)

Here is how to make those kinds of changes to a package: https://trac.macports.org/wiki/howto/PatchLocal

See also [MACPORTS.md](MACPORTS.md) for details on how MacPorts is used to build GIMP.

## Branches

**Note**: CircleCI is currently set up to build the `master` and `gimp-2-10` branchs on a nightly basis (and pulls the latest GIMP code from the same branches on the [GIMP repo](https://gitlab.gnome.org/GNOME/gimp). It also builds any branch of this repo that is pushed to.

## Releases

For releases, create a release branch, and go into the `/ports/gimp` directory and edit the `Portfile` to update the version number and set the correct release tag (there are examples which are commented out). Then push the branch to this repo and CircleCI will build it.

When ready, the branch can be merged to `master` or `gimp-2-10` as appropriate. The release should then be tagged on this repo (use the same tag as on the [GIMP repo](https://gitlab.gnome.org/GNOME/gimp)). That build will be the release build (in the Circle CI artifacts). There will be two builds, one for arm64 and one for x86_64. These should be downloaded and tested locally to make sure they work, and then provided to the GIMP team for distribution.

Once everything is fine with the release, create a new branch for going back to building the head release. Update the version appropriately in the `Portfile` and set to pulling the `master` branch of the GIMP repo. Once this is working properly, merge the new branch back to `master`.

## (Out of date) Steps in the CircleCI [config.yml](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/blob/master/.circleci/config.yml) are:

**NOTE** This section is out of date. Needs to be updated.

- Install Python 3 (Rust is pre-installed) as they are required for the GIMP dependencies.
- Set up macOS 10.13 SDK. This is needed to ensure that GIMP can run on macOS 10.13+. See [this article](https://smallhacks.wordpress.com/2018/11/11/how-to-support-old-osx-version-with-a-recent-xcode/) for the details.
- Install [fork of the gtk-mac-bundler](https://gitlab.gnome.org/lukaso/gtk-mac-bundler) - the tool which helps to create macOS application bundles for the GTK apps. This will hopefully shift to official [gtk-mac-bundler](https://github.com/GNOME/gtk-mac-bundler)
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
- Notarize package using Apple `notarytool` utility
- Upload a DMG to the CircleCI build artifacts

## Managing the Circle CI build ##

The Circle CI build creates some specific issues that a packager needs to be aware of.

### CircleCI Problems ###

- **Timeouts** Steps in a job can take max 3 hours before being cancelled.
- **Timeouts 2** While building, the build will be cancelled if there is no output to the console for 10 minutes.
- **Console overflow** There is a limit of 50MB of console output. If this is exceeded, no more output is captured. If there is an error at this point, you will not be able to see what happened.
- **Caching** Cache saves and restores are quite slow, and are only saved if the cache key changes. Therefore it is critical if any build activity is taken on, that the cache key is changed.
- **Caching 2** If a build step fails before the cache is saved, nothing will be cached. This can be painful if the build step takes a long time.
- **Users** The user isn't saved by the cache. This means that MacPorts, which creates it's own user, needs to be reinstalled on every build step (whenever a new container/VM is started).

### MacPorts Problems ###

- **Need to build for 10.13 on a modern OS** GIMP runs on macOS 10.13 and above. However, the MacPorts build environment is macOS 12 and up. MacPorts has to be configured to use the 10.13 SDK and to build for 10.13. This sometimes goes awry. Additionally, MacPorts is designed primarily to use packages that are built for the current OS. Since we are not in this situation, we have to build all runtime packages from source rather than using pre-built packages. This is more error prone and slow. Some packages are so slow to build and are only needed at compile time that we attempt to use pre-built packages for them (`rust`, `cmake` and `llvm` are the biggest ones). However, we have to first build their dependencies from source since those may well be needed at runtime.
- **Flaky package upgrades** MacPorts package upgrades rarely fail individually, but GIMP uses a lot of them and so failures occur frequently. These are usually rectified within a few days.
- **Flaky self updates and upgrades** MacPorts self updates and package upgrades are also flaky. This is why each package is first cleaned and then installed. Additional issues can occur because we are building two different versions of GIMP so the packages sometimes don't overlap. The biggest issues seem to arise when a new Portfile can no longer uninstall a previous installation. Occasionally files have been left behind during uninstalls which cannot be overridden by the new install.
- **MacPorts take a very generous view of dependencies** This means that many packages that are not needed for GIMP, are required in order for the build to complete. Examples are needing all major versions of `Python` and `Perl`. This increases build time but more significantly, increases what can go wrong in a build.

When everything has gone wrong, the only solution is to up the version in the file `./ports/cache_break` and push that to the repo. This will cause a full rebuild of everything from scratch. But beware that this can fail when new versions of package are suddenly included.
### Problems and workarounds in CircleCI Build ###

Problems and workaround:

- **Timeouts** Steps in a job can take max 3 hours before being cancelled. To work around this, the build has been split into multiple steps, each of which has been curated to take less than 3 hours. However, the build steps are merged when there is a valid cache, because the save and load of the cache for each step take about 35 minutes per step.
- **Length of build** The full cache is broken by changing the first part of the cache key [see below for caching principles] whenever the file `./ports/cache_break` is changed. This will trigger a full build of everthing from scratch and will take near 7 hours to complete. Recommended only in extreme circumstances.
- **caching** The cache is saved on every build step, due to the need for any changes to pass to the next build step. This can take from 5 to 30 minutes as the full cache weighs in at a whopping 9GB. This is way above the recommended limit of Circle CI but is unavoidable due to the build time limits.

#### More on caching ###

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

 - CircleCI [gimp-macos-build project](https://circleci.com/gh/GNOME/gimp-macos-build)

## Known bugs and limitations (merge requests are welcome!)

- [XPM import/export will not work](https://gitlab.gnome.org/Infrastructure/gimp-macos-build/issues/6) due to missing libXpm/macOS.
- No scanning support. Scanner support needs to be re-implemented using ImageCaptureCore
framework. Probably could be a small Python plugin as [there is a module](https://pypi.org/project/pyobjc-framework-ImageCaptureCore/) for it. As a workaround you can use your scanner utility or any other third-party tool.
- Some of the system modifiers are not working correctly, e.g., `Command+H`, `Command+~`, etc.
- Loading of remote HTTP objects is not supported due to [Glib limitations on macOS](https://gitlab.gnome.org/GNOME/glib/issues/1579)

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
