#!/usr/bin/env bash
#####################################################################
 # macports_install_packages.sh: installs gimp dependencies         #
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

if [ "$1" == "circleci" ]; then
  circleci=true
fi

function sup_port() {
	if [ $circleci ]; then
    "$@" | cat
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then exit "${PIPESTATUS[0]}"; fi
  else
    "$@"
  fi
}

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source ~/.profile
export PATH=$PREFIX/bin:$PATH

pushd ~/project/ports
portindex
popd

# required by poppler. Not sure why it is not installed when poppler is installed
$dosudo port clean boost176
$dosudo port -v -N install boost176
$dosudo port clean gimp3
sup_port $dosudo port -k -N install gimp3 +debug
