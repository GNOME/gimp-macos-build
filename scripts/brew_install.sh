#!/usr/bin/env bash
#####################################################################
 # macports_uninstall.sh: installs homebrew                         #
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

PREFIX=$HOME/homebrew

if [ ! -d "$PREFIX" ]
then
  mkdir -p $PREFIX && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "${PREFIX}"
fi

if [ "$build_arm64" = true ] ; then
    echo "*** Setup 11.3 SDK"
    cd /Library/Developer/CommandLineTools/SDKs
    if [ ! -d "MacOSX11.3.sdk" ]
    then
        sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz' | sudo tar -xzf -
    fi
    echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX11.3.sdk' > $PREFIX/.profile
    echo 'export MACOSX_DEPLOYMENT_TARGET=11.3' >> $PREFIX/.profile
    echo 'export HOMEBREW_MACOS_VERSION=11.3' >> $PREFIX/.profile
    echo 'export GIMP_ARM64=true' >> $PREFIX/.profile
else
    echo "*** Setup 10.12 SDK"
    cd /Library/Developer/CommandLineTools/SDKs
    if [ ! -d "MacOSX10.12.sdk" ]
    then
        sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX10.12.sdk.tar.xz' | sudo tar -xzf -
    fi
    echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk' > $PREFIX/.profile
    echo 'export MACOSX_DEPLOYMENT_TARGET=10.12' >> $PREFIX/.profile
    echo 'export HOMEBREW_MACOS_VERSION=10.12' >> $PREFIX/.profile
    # Removes /usr/include being added to CFLAGS on 10.12 (no idea why)
    # Needed in order to build `poppler` and `poppler-slim`
    echo 'export PKG_CONFIG_SYSTEM_INCLUDE_PATH=/usr/include' >> $PREFIX/.profile
fi

# remove existing brew from path
if BREWLOC=$(which brew); then
  BREWDIR="$(dirname $(dirname "${BREWLOC}"))"

  BREWDIR_BIN="${BREWDIR}/bin"
  PATH=:$PATH:
  PATH=${PATH//:$BREWDIR_BIN:/:}
  PATH=${PATH#:}; PATH=${PATH%:}

  BREWDIR_BIN="${BREWDIR}/sbin"
  PATH=:$PATH:
  PATH=${PATH//:$BREWDIR_BIN:/:}
  PATH=${PATH#:}; PATH=${PATH%:}
fi

# Add new brew to path
echo "export PATH='$HOME/homebrew/bin:$HOME/homebrew/sbin:$PATH'" >> $PREFIX/.profile
echo 'unset HOMEBREW_PREFIX' >> $PREFIX/.profile
echo 'unset HOMEBREW_CELLAR' >> $PREFIX/.profile
echo 'unset HOMEBREW_REPOSITORY' >> $PREFIX/.profile

cd $PREFIX
source .profile
brew update

patch -p1 < ~/project/patches/homebrew-support-setting-os.patch

brew tap --force-auto-update infrastructure/homebrew-gimp https://gitlab.gnome.org/Infrastructure/gimp-macos-build.git

~/project/scripts/brew_set_tap_branch.sh

# probably not needed. Will have to test full install
#ensure it has the right system path
# brew reinstall pkg-config

# saves some hassle with repos if git secrets is configured
echo "***Installing git-secrets"
brew install -s git-secrets

# for some reason doesn't auto install. Appears to be related to a source installation
# requiring a source installation that then requires subversion.
# Won't build under 10.12
echo "***Installing subversion"
brew install --only-dependencies -s subversion
HOMEBREW_MACOS_VERSION= MACOSX_DEPLOYMENT_TARGET= brew install subversion
echo "***Installing doxygen"
brew install --only-dependencies -s doxygen
HOMEBREW_MACOS_VERSION= MACOSX_DEPLOYMENT_TARGET= brew install doxygen

