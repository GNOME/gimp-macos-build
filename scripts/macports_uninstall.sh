#!/usr/bin/env bash
####################################################################
# macports_uninstall.sh: uninstalls macports                       #
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

arch=$(uname -m)
if [ "$arch" = 'arm64' ]; then
  build_arm64=true
else
  build_arm64=false
fi
echo "*** Build: $arch"

function pure_version() {
  echo '0.2'
}

function version() {
  echo "macports_uninstall.sh $(pure_version)"
}

function usage() {
  version
  echo ""
  echo "Uninstalls MacPorts (or just formulas)."
  echo "Usage:  $(basename "$0") [--formulas-only] [--version] [--help]"
  echo ""
  echo "Options:"
  echo "  --formulas-only"
  echo "      only uninstall formulas, not macports itself. Needed for CI where deleting users requires"
  echo "      accepting a dialog box."
  echo "  --dirgimp"
  echo "      uninstalls macports builds from a custom prefix"
  echo "  --version         show tool version number"
  echo "  -h, --help        display this help"
  exit 0
}

formulasonly=''

while test "${1:0:1}" = "-"; do
  case $1 in
  --formulas-only)
    formulasonly="true"
    shift
    ;;
  --dirgimp)
    GIMP_PREFIX="$2"
    shift 2
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

if [ -z "$GIMP_PREFIX" ]; then
  export GIMP_PREFIX=${HOME}/macports-gimp3-${arch}
fi
echo "**Uninstalling MacPorts in $GIMP_PREFIX"
export PATH=$GIMP_PREFIX/bin:$PATH

echo "Macports installed at $(which port &>/dev/null)"
if which port &>/dev/null; then
  echo "Uninstalling formulas"
  port -fp uninstall installed || true
fi

if [ -n "$formulasonly" ]; then
  exit 0
fi

echo "Uninstalling MacPorts build"
if [ -n "${GIMP_PREFIX}" ]; then
  rm -rf "$GIMP_PREFIX"
fi
