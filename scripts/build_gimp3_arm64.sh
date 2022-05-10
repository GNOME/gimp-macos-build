# Build script for M1 Mac version of gimp 2.99.

# Must be run from home directory
cd $HOME

echo "*** checkout gimp-macos-build"
if [ ! -d ~/project ]; then
    mkdir -p ~/project
    git clone https://gitlab.gnome.org/Infrastructure/gimp-macos-build.git project
fi

# ~/project/swap-local-build.sh --folder gimp299-arm64
# if [ ! -z "${BRANCH}" ]; then
#   cd ~/project
#   git checkout wip/lukaso/tests-2.99-arm64
#   cd $HOME
# fi

echo "*** Setup 11.3 SDK"
cd /Library/Developer/CommandLineTools/SDKs
if [ ! -d "MacOSX11.3.sdk" ]
then
    sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz' | sudo tar -xzf -
fi
echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX11.3.sdk' > ~/.profile
echo 'export MACOSX_DEPLOYMENT_TARGET=11.0' >> ~/.profile

echo "*** Setup JHBuild"
cd $HOME
mkdir -p ~/.config && cp ~/project/jhbuildrc-gtk-osx-gimp-2.99 ~/.config/jhbuildrc-custom
echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH:$HOME/.new_local/bin"' >> ~/.profile
echo 'export GIMP_DEBUG=true' >> ~/.profile
echo 'export GIMP_ARM64=true' >> ~/.profile
source ~/.profile
PIPENV_YES=1 ~/project/gtk-osx-setup.sh

echo 'export ARCHFLAGS="-arch arm64"' >> ~/.profile

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

echo "*** Bootstrap"
source ~/.profile && jhbuild build icu libnsgif meta-gtk-osx-freetype meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build GIMP dependencies part 1 (without gegl/babl)"
source ~/.profile && jhbuild build openjpeg ilmbase json-c libde265 nasm x265
source ~/.profile && jhbuild build frodo-getopt xmlto pycairo pygobject3 gtk-mac-integration-python libarchive libyaml uuid
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build GIMP dependencies part 2"
source ~/.profile && jhbuild build gimp-common-deps appstream-glib
source ~/.profile && jhbuild build python3
echo "*** Cleanup"
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Build all WebKit dependencies"
source ~/.profile && jhbuild build enchant libpsl sqlite vala gnutls libgpg-error glib-networking
source ~/.profile && jhbuild buildone libsoup libgcrypt libwebp
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
jhbuild build gimp299

echo "Building GIMP help (en) from git"
# source ~/.profile && ALL_LINGUAS=en jhbuild build gimp-help-git
# Cleanup
# find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

echo "*** Importing signing certificate"
# mkdir ${HOME}/codesign && cd ${HOME}/codesign
# echo "$osx_crt" | base64 -D > gnome.pfx
# curl 'https://developer.apple.com/certificationauthority/AppleWWDRCA.cer' > apple.cer
# security create-keychain -p "" signchain
# security set-keychain-settings signchain
# security unlock-keychain -u signchain
# security list-keychains  -s "${HOME}/Library/Keychains/signchain-db" "${HOME}/Library/Keychains/login.keychain-db"
# security import apple.cer -k signchain  -T /usr/bin/codesign
# security import gnome.pfx  -k signchain -P "$osx_crt_pw" -T /usr/bin/codesign
# security set-key-partition-list -S apple-tool:,apple: -k "" signchain
# rm -rf ${HOME}/codesign

echo "*** Creating DMG package"
source ~/.profile
cd ${HOME}/project/package
jhbuild run ./build299.sh debug

echo "*** Notarizing DMG package"
# source ~/.profile
# cd ${HOME}/project/package
# jhbuild run ./notarize.sh
