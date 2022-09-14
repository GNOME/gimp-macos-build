#!/usr/bin/env bash
#####################################################################
 # conda_install.sh: installs conda                                 #
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
  CONDA_SUBDIR=osx-arm64
else
  build_arm64=false
  echo "*** Build: x86_64"
  CONDA_SUBDIR=osx_64
fi

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

brew install pyenv-virtualenv # you might have this from before, no problem
if [ ! $(pyenv install --list | grep "anaconda3-2022.05") ]; then
  pyenv install anaconda3-2022.05
  pyenv virtualenv anaconda3-2022.05
fi
eval "$(pyenv init -)"
pyenv activate anaconda3-2022.05

echo '# Conda build profile - auto generated, do not modify' > $HOME/.gimp_build_profile

if [ "$build_arm64" = true ] ; then
    sdk=11.3
    echo 'export GIMP_ARM64=true' >> $HOME/.gimp_build_profile
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
echo "export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX${sdk}.sdk" >> $HOME/.gimp_build_profile
echo "export MACOSX_DEPLOYMENT_TARGET=${sdk}" >> $HOME/.gimp_build_profile
echo "export HOMEBREW_MACOS_VERSION=${sdk}" >> $HOME/.gimp_build_profile

source $HOME/.gimp_build_profile

PIP_EXISTS_ACTION=w conda env create -f $PROJECT_DIR/scripts/environment-mac.yaml
conda activate gimp_build
