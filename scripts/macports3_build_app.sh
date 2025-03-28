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

if [[ $(uname -m) == 'arm64' ]]; then
  arch='arm64'
  echo "*** Build: arm64"
else
  arch='x86_64'
  echo "*** Build: x86_64"
fi
source ~/.profile-gimp${VGIMP}-${arch}
export PATH=$PREFIX/bin:$PATH

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pushd $PROJECT_DIR/package
./macports_build_app.sh debug
./macports_build_plugin_developer_app.sh
popd
