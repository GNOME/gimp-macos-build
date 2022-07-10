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
  mkdir -p $PREFIX && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
fi

echo 'export MACOSX_DEPLOYMENT_TARGET=11.3' > $PREFIX/.profile
echo 'export HOMEBREW_MACOS_VERSION=11.3' > $PREFIX/.profile

echo "*** Setup 11.3 SDK"

pushd /Library/Developer/CommandLineTools/SDKs
if [ ! -d "MacOSX11.3.sdk" ]
then
    sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz' | sudo tar -xzf -
fi
popd
echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX11.3.sdk' >> $PREFIX/.profile

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

brew tap --force-auto-update lukaso/homebrew-gimp https://gitlab.gnome.org/lukaso/homebrew-gimp.git

# for some reason doesn't auto install. Appears to be related to a source installation
# requiring a source installation that then requires subversion.
brew install -s subversion
