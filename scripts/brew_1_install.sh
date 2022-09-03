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

if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
  PREFIX=$HOME/homebrew
else
  build_arm64=false
  echo "*** Build: x86_64"
  PREFIX=$HOME/homebrew_x86_64
fi

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

if [ ! -d "$PREFIX" ]
then
  mkdir -p $PREFIX && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "${PREFIX}"
fi

echo '# Homebrew build profile - auto generated, do not modify' > $PREFIX/.profile

if [ "$build_arm64" = true ] ; then
    sdk=11.3
    echo 'export GIMP_ARM64=true' >> $PREFIX/.profile
else
    sdk=10.14
fi

echo "*** Setup ${sdk} SDK"
echo "NOTE: Admin password require to install SDK"
cd /Library/Developer/CommandLineTools/SDKs
if [ ! -d "MacOSX${sdk}.sdk" ]
then
    sudo curl -L "https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX${sdk}.sdk.tar.xz" | sudo tar -xzf -
fi
echo "export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX${sdk}.sdk" >> $PREFIX/.profile
echo "export MACOSX_DEPLOYMENT_TARGET=${sdk}" >> $PREFIX/.profile
echo "export HOMEBREW_MACOS_VERSION=${sdk}" >> $PREFIX/.profile

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
echo "export PATH='$PREFIX/bin:$PREFIX/sbin:$PATH'" >> $PREFIX/.profile
echo 'unset HOMEBREW_PREFIX' >> $PREFIX/.profile
echo 'unset HOMEBREW_CELLAR' >> $PREFIX/.profile
echo 'unset HOMEBREW_REPOSITORY' >> $PREFIX/.profile

source $PREFIX/.profile

${PROJECT_DIR}/scripts/_brew_ensure_patched.sh
brew update

# saves some hassle with repos if git secrets is configured
echo "***Installing git-secrets"
brew install -s git-secrets

brew install --only-dependencies -s subversion
brew install --only-dependencies -s python@3.10
brew install --only-dependencies -s rust

echo "curl causes all kinds of problems on build (subversion, llibmng)"
HOMEBREW_MACOS_VERSION= MACOSX_DEPLOYMENT_TARGET= brew install libunistring
brew install --only-dependencies -s curl

# for some reason doesn't auto install. Appears to be related to a source installation
# requiring a source installation that then requires subversion.
# Won't build under 10.12
echo "***Installing subversion (for netpbm)"
# was struggling to build on x86_64 until adding `--debug`
brew install --debug subversion
echo "***Installing python@3.10 (for building in general)"
brew install python@3.10

# How to disable setting of SDK
# HOMEBREW_MACOS_VERSION= MACOSX_DEPLOYMENT_TARGET= brew install doxygen

echo "***Installing rust (won't build on 10.13)"
brew install rust
brew install curl
brew link --force curl

brew update

# Required for building package/DMG
brew install gawk

${PROJECT_DIR}/scripts/_brew_set_tap_branch.sh
${PROJECT_DIR}/scripts/_brew_fixup_prs_not_merged.sh
