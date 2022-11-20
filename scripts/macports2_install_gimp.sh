#!/usr/bin/env bash
#####################################################################
 # macports2_install_gimp.sh: installs gimp dependencies         #
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

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source ~/.profile
export PATH=$PREFIX/bin:$PATH

if [ -z "$circleci" ]; then
  local="+local"
fi

function sup_port() {
	if [ -n "$circleci" ]; then
    "$@" | cat
    status="${PIPESTATUS[0]}"
    if [ "${status}" -ne 0 ]; then exit "${status}"; fi
  else
    "$@"
  fi
}

pushd ~/project/ports
$dosudo portindex
popd

# Force new install of gimp so latest changes are pulled from gitlab
# deal with 'Error: Port gimp210 not found'
$dosudo port -N uninstall installed and gimp210 || true
$dosudo port clean gimp210 || true
$dosudo port -N uninstall installed and gimp3 || true
$dosudo port clean gimp3 || true
sup_port $dosudo port -v -k -N install gimp3 +vala ${local}
