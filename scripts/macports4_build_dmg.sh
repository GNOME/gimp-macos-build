#!/usr/bin/env bash
####################################################################
# macports3_build_dmg.sh: Builds gimp dmg                          #
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

set -e

export VGIMP=3

arm64_file="$HOME/.profile-gimp${VGIMP}-arm64"
x86_64_file="$HOME/.profile-gimp${VGIMP}-x86_64"
if [ -f "$arm64_file" ] && [ -f "$x86_64_file" ]; then
  # Both files are present, decide based on current arch because this is a
  # local build
  if [[ $(uname -m) == 'arm64' ]]; then
    arch='arm64'
    echo "*** Build: arm64"
  else
    arch='x86_64'
    echo "*** Build: x86_64"
  fi
  source "$HOME/.profile-gimp${VGIMP}-${arch}"
elif [ -f "$arm64_file" ]; then
  echo "*** Build: arm64"
  source "$arm64_file"
elif [ -f "$x86_64_file" ]; then
  echo "*** Build: x86_64"
  source "$x86_64_file"
else
  echo "*** No suitable profile found for GIMP"
  exit 1
fi

if [ -n "$GIMP_ARM64" ]; then
  build_type=arm64
  echo "*** Build: arm64"
else
  build_type=x86_64
  echo "*** Build: x86_64"
fi

export PATH=$PREFIX/bin:$PATH

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pushd $PROJECT_DIR/package
./macports_build_dmg.sh ${build_type}
EXTENSION="-plugin-developer" ./macports_build_dmg.sh ${build_type}
popd
