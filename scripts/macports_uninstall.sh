#!/usr/bin/env bash
#####################################################################
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

source ~/.profile
export PATH=$PREFIX/bin:$PATH


function pure_version() {
	echo '0.1'
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
    echo "  --version         show tool version number"
    echo "  -h, --help        display this help"
    exit 0
}

formulasonly=''

while test "${1:0:1}" = "-"; do
	case $1 in
	--formulas-only)
		formulasonly="true"
		shift;;
	-h | --help)
		usage;;
	--version)
		version; exit 0;;
	-*)
		echo "Unknown option $1. Run with --help for help."
		exit 1;;
	esac
done

if which port &> /dev/null; then
  echo "Uninstalling formulas"
  $dosudo port -fp uninstall installed || true
fi

if [ -n "$formulasonly" ]; then
  exit 0
fi

echo "Uninstalling MacPorts"
if [ -z "${dosudo}" ]; then
  if [ -n "${PREFIX+x}" ]; then
    rm -rf "$PREFIX"
  fi
else
  $dosudo dscl . -delete /Users/macports
  $dosudo dscl . -delete /Groups/macports

  $dosudo rm -rf \
      /opt/local \
      /Applications/DarwinPorts \
      /Applications/MacPorts \
      '/Library/LaunchDaemons/org.macports.*' \
      '/Library/Receipts/DarwinPorts*.pkg' \
      '/Library/Receipts/MacPorts*.pkg' \
      /Library/StartupItems/DarwinPortsStartup \
      /Library/Tcl/darwinports1.0 \
      /Library/Tcl/macports1.0 \
      ~/.macports
fi
