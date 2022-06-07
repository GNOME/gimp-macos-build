#!/usr/bin/env bash
#####################################################################
 # build_gimp.sh: builds gimp on a local mac                       #
 #                                                                  #
 # Copyright 2022 Lukas Oberhuber <lukaso@gmail.com>                #
 #                                                                  #
 # This program is free software; you can redistribute it and/or    #
 # modify it under the terms of the GNU General Public License as   #
 # published by the Free Software Foundation; either version 2 of   #
 # the License, or (at your option) any later version.              #
 #                                                                  #
 # This program is distributed in the hope that it will be useful,  #
 # but WITHOUT ANY WARRANTY; without even the implied warranty of   #
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    #
 # GNU General Public License for more details.                     #
 #                                                                  #
 # You should have received a copy of the GNU General Public License#
 # along with this program; if not, contact:                        #
 #                                                                  #
 # Free Software Foundation           Voice:  +1-617-542-5942       #
 # 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652       #
 # Boston, MA  02110-1301,  USA       gnu@gnu.org                   #
 ####################################################################

set -e;

function pure_version() {
	echo '0.1'
}

function version() {
	echo "build_gimp.sh $(pure_version)"
}

function usage() {
    version
    echo ""
    echo "Builds Gimp 2.10 locally."
    echo "Usage:  $(basename $0) [options]"
    echo ""
    echo "Builds Gimp 2.10 or subsets of the program to facilitate rapid"
    echo "local development."
    echo "By default builds all of Gimp, end to end."
    echo "Gimp can then be run from '~/gtk/inst/bin/gimp'"
    echo "Options:"
    echo "  --nodmg"
    echo "      skips building the DMG (big build speedup)"
    echo "  --shell"
    echo "      drops into a jhbuild shell for rapid rebuilds of a single"
    echo "      package"
    echo "  --build-package package_name"
    echo "      force build a particular package (uses 'jhbuild buildone --force')"
    echo "  --wipe-out-rebuild package_name"
    echo "      re-downloads the package before building. Otherwise same as"
    echo "      --build-package (experimental)"
    echo "  --version         show tool version number"
    echo "  -h, --help        display this help"
    exit 0
}

NO_DMG=''
SHELL_OUT=''
ONLY_PACKAGE=''
WIPE_OUT_PACKAGE=''

while test "${1:0:1}" = "-"; do
	case $1 in
	--nodmg)
		NO_DMG="true"
		shift;;
	--shell)
		SHELL_OUT="true"
		shift;;
	--build-package)
		ONLY_PACKAGE=$2
		shift; shift;;
    --wipe-out-rebuild)
		WIPE_OUT_PACKAGE=$2
		shift; shift;;
	-h | --help)
		usage;;
	--version)
		version; exit 0;;
	-*)
		echo "Unknown option $1. Run with --help for help."
		exit 1;;
	esac
done

if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
else
  build_arm64=false
  echo "*** Build: x86_64"
fi

# Must be run from home directory
cd $HOME

echo "*** checkout gimp-macos-build"
if [ ! -d ~/project ]; then
    mkdir -p ~/project
    git clone https://gitlab.gnome.org/Infrastructure/gimp-macos-build.git project
fi

# if [ "$build_arm64" = true ] ; then
#     ~/project/swap-local-build.sh --folder gimp210
#     if [ ! -z "${BRANCH}" ]; then
#     cd ~/project
#     git checkout wip/lukaso/tests-2.10
#     cd $HOME
#     fi
# fi

if [ "$build_arm64" = true ] ; then
    echo "*** Setup 11.3 SDK"
    cd /Library/Developer/CommandLineTools/SDKs
    if [ ! -d "MacOSX11.3.sdk" ]
    then
        sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz' | sudo tar -xzf -
    fi
    echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX11.3.sdk' > ~/.profile
    echo 'export MACOSX_DEPLOYMENT_TARGET=11.0' >> ~/.profile
    echo 'export ARCHFLAGS="-arch arm64"' >> ~/.profile
    echo 'export GIMP_ARM64=true' >> ~/.profile
else
    echo "*** Setup 10.12 SDK"
    cd /Library/Developer/CommandLineTools/SDKs
    if [ ! -d "MacOSX10.12.sdk" ]
    then
        sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.12.sdk.tar.xz' | sudo tar -xzf -
    fi
    echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk' > ~/.profile
    echo 'export MACOSX_DEPLOYMENT_TARGET=10.12' >> ~/.profile
    echo 'export ARCHFLAGS="-arch x86_64"' >> ~/.profile
    echo 'export PYENV_PYTHON_VERSION=3.10.0' >> ~/.profile
fi

echo "*** Setup JHBuild"
cd $HOME
mkdir -p ~/.config && cp ~/project/jhbuildrc-gtk-osx-gimp-2.10 ~/.config/jhbuildrc-custom
echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH:$HOME/.new_local/bin"' >> ~/.profile
echo 'export GIMP_DEBUG=true' >> ~/.profile
source ~/.profile
PIPENV_YES=1 ~/project/gtk-osx-setup.sh

echo "*** bootstrap"
# $HOME/.new_local/bin/jhbuild bootstrap-gtk-osx-gimp
$HOME/.new_local/bin/jhbuild bootstrap-gtk-osx
cat ~/.profile

echo "*** Setup gtk-mac-bundler"
if [ ! -d "$HOME/Source/gtk-mac-bundler" ]
then
    cd ~/Source
    git clone https://gitlab.gnome.org/lukaso/gtk-mac-bundler
    cd gtk-mac-bundler
    make install
    cd ~
fi

if [ ! -z "${ONLY_PACKAGE}" ]; then
    echo "*** Only building ${ONLY_PACKAGE}"
    source ~/.profile && jhbuild buildone --force ${ONLY_PACKAGE}
    exit 0;
fi

if [ ! -z "${WIPE_OUT_PACKAGE}" ]; then
    echo "*** Only building ${WIPE_OUT_PACKAGE}"
    source ~/.profile && jhbuild buildone -afc ${WIPE_OUT_PACKAGE}
    exit 0;
fi

if [ ! -z "${SHELL_OUT}" ]; then
    echo "*** Enable this to shell out to jhbuild"
    export PACKAGE=gimp
    echo "Once you've entered the shell, cd to the build directory."
    echo "For example, ${PACKAGE} is built here:"
    echo "cd .cache/jhbuild/build/$PACKAGE"
    echo "Then you can execute the build."
    echo "head config.log"
    echo "will tell you what the configure was (for autotools)"
    echo "*examples:"
    echo "**autotools:"
    echo "~/gtk/source/gimp/configure --prefix ~/gtk/inst --without-x --with-build-id=org.gimp.GIMP_official --with-revision=0"
    echo "make && make install"
    echo "make uninstall"
    echo "**meson:"
    echo "meson --prefix ~/gtk/inst --libdir lib -Dopenssl=enabled --wrap-mode=nofallback ~/gtk/source/glib-networking-2.68.0"
    echo "ninja && ninja install"
    echo "ninja uninstall"
    echo "don't forget you might have to --reconfigure meson"
    echo "Call:"
    echo "exit"
    echo "To carry on."
    source ~/.profile && jhbuild shell
    exit 0;
fi

echo "*** Bootstrap"
source ~/.profile && jhbuild build icu meta-gtk-osx-freetype meta-gtk-osx-bootstrap meta-gtk-osx-core
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build GIMP dependencies part 1 (without gegl/babl)"
source ~/.profile && jhbuild build suitesparse lcms libunistring gmp libnettle libtasn1 gnutls libjpeg readline python2 glib-networking openjpeg  gtk-mac-integration-gtk2 poppler poppler-data
source ~/.profile && jhbuild build json-glib p2tc exiv2 gexiv2 ilmbase openexr libwebp libcroco librsvg-24 json-c
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build GIMP dependencies part 2"
source ~/.profile && jhbuild build libmypaint mypaint-brushes libde265 nasm x265 libheif aalib shared-mime-info iso-codes libwmf libmng ghostscript
source ~/.profile && jhbuild build pycairo pygobject pygtk gtk-mac-integration-gtk2-python
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build all WebKit dependencies"
source ~/.profile && jhbuild build enchant libpsl sqlite vala gnutls
source ~/.profile && jhbuild buildone libsoup
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

# echo "*** Build WebKit"
# source ~/.profile && jhbuild build webkit2gtk3
# echo "*** Cleanup"
# find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build and test babl/gegl"
source ~/.profile && jhbuild build --check babl gegl

echo "*** Build GIMP"
# XXX `make check` is not working reliably under circle ci, so we are
# not using --check flag
source ~/.profile
jhbuild build gimp

# echo "Building GIMP help (en) from git"
# # source ~/.profile && ALL_LINGUAS=en jhbuild build gimp-help-git
# # Cleanup
# # find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

# echo "*** Importing signing certificate"
# # mkdir ${HOME}/codesign && cd ${HOME}/codesign
# # echo "$osx_crt" | base64 -D > gnome.pfx
# # curl 'https://developer.apple.com/certificationauthority/AppleWWDRCA.cer' > apple.cer
# # security create-keychain -p "" signchain
# # security set-keychain-settings signchain
# # security unlock-keychain -u signchain
# # security list-keychains  -s "${HOME}/Library/Keychains/signchain-db" "${HOME}/Library/Keychains/login.keychain-db"
# # security import apple.cer -k signchain  -T /usr/bin/codesign
# # security import gnome.pfx  -k signchain -P "$osx_crt_pw" -T /usr/bin/codesign
# # security set-key-partition-list -S apple-tool:,apple: -k "" signchain
# # rm -rf ${HOME}/codesign

if [ -z "${NO_DMG}" ]; then
    echo "*** Creating DMG package"
    source ~/.profile
    cd ${HOME}/project/package
    jhbuild run ./build.sh debug
else
    echo "*** Skipping building DMG"
fi

# echo "*** Notarizing DMG package"
# # source ~/.profile
# # cd ${HOME}/project/package
# # jhbuild run ./notarize.sh
