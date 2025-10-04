#!/usr/bin/env bash
####################################################################
# macports2_install_gimp.sh: installs gimp dependencies            #
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

arch=$(uname -m)
echo "*** Build: $arch"
source ~/.profile-gimp-${arch}

if [ -z "$GIMP_PREFIX" ]; then
  export GIMP_PREFIX=${HOME}/macports-gimp3-${arch}
fi
export PATH=$GIMP_PREFIX/bin:$PATH

function sup_port() {
  if [ -n "$circleci" ]; then
    "$@" | cat
    status="${PIPESTATUS[0]}"
    if [ "${status}" -ne 0 ]; then exit "${status}"; fi
  else
    "$@"
  fi
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pushd ${PROJECT_DIR}/ports
portindex
popd

# Force new install of gimp so latest changes are pulled from gitlab
# deal with 'Error: Port gimp not found'
port -N uninstall installed and gimp-official || true
port clean gimp-official || true
rm ${PROJECT_DIR}/package/gimp.icns || true
rm ${PROJECT_DIR}/package/gimp-dmg.png || true

sup_port port -v -k -N install gimp-official +vala ${local}

port installed > ${GIMP_PREFIX}/SBOM.txt
