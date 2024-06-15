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

export VGIMP=3

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

function usage() {
  version
  echo ""
  echo "Builds Gimp."
  echo "Usage:  $(basename $0) [options]"
  echo ""
  echo "Builds Gimp."
  echo "Options:"
  echo "  --x86_64"
  echo "      does x86_64 cross compile"
  echo "  --version         show tool version number"
  echo "  -h, --help        display this help"
  exit 0
}

# default
arch='arm64'

while test "${1:0:1}" = "-"; do
  case $1 in
  --x86_64)
    arch='x86_64'
    shift
    ;;
  -h | --help)
    usage
    ;;
  --version)
    version
    exit 0
    ;;
  -*)
    echo "Unknown option $1. Run with --help for help."
    exit 1
    ;;
  esac
done

if [[ $arch == 'arm64' ]]; then
  arch='arm64'
  echo "*** Build: arm64"
else
  arch='x86_64'
  echo "*** Build: x86_64"
fi
source ~/.profile-gimp${VGIMP}-${arch}
export PATH=$PREFIX/bin:$PATH

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
portindex
popd

# Force new install of gimp so latest changes are pulled from gitlab
# deal with 'Error: Port gimp210 not found'
port -N uninstall installed and gimp210 || true
port clean gimp210 || true
port -N uninstall installed and gimp3 || true
port clean gimp3 || true
sup_port port -v -k -N install gimp${VGIMP} +vala ${local}
