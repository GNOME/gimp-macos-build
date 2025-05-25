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

arm64_file="$HOME/.profile-gimp-arm64"
x86_64_file="$HOME/.profile-gimp-x86_64"
if [ -f "$arm64_file" ] && [ -f "$x86_64_file" ]; then
  # Both files are present, decide based on current arch because this is a
  # local build
  arch=$(uname -m)
  source "$HOME/.profile-gimp-${arch}"
elif [ -f "$arm64_file" ]; then
  source "$arm64_file"
elif [ -f "$x86_64_file" ]; then
  source "$x86_64_file"
else
  echo "*** No suitable profile found for GIMP"
  exit 1
fi

if [ -n "$GIMP_ARM64" ]; then
  export arch=arm64
else
  export arch=x86_64
fi
echo "*** Build: $arch"

if [ -z "$GIMP_PREFIX" ]; then
  export GIMP_PREFIX=${HOME}/macports-gimp3-${arch}
fi
export PATH=$GIMP_PREFIX/bin:$PATH

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pushd $PROJECT_DIR/package
./macports_build_dmg.sh ${arch}
EXTENSION="-plugin-developer" ./macports_build_dmg.sh ${arch}
popd
