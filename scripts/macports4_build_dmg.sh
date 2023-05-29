#!/usr/bin/env bash
#####################################################################
 # macports3_build_dmg.sh: Builds gimp2 dmg                         #
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

source ~/.profile-gimp2

if [ -n "$GIMP_ARM64" ]; then
  build_arm64=true
  build_type=arm64
  echo "*** Build: arm64"
else
  build_arm64=false
  build_type=x86_64
  echo "*** Build: x86_64"
fi

export PATH=$PREFIX/bin:$PATH

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

pushd $PROJECT_DIR/package
./macports_build_dmg.sh ${build_type}
popd