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

if ! which port &> /dev/null; then
  $dosudo port -fp uninstall installed || true
fi

if [ -z ${dosudo} ]; then
  if [ ! -z ${PREFIX+x} ]; then
    rm -rf $PREFIX
  fi
else
  $dosudo dscl . -delete /Users/macports
  $dosudo dscl . -delete /Groups/macports

  $dosudo rm -rf \
      /opt/local \
      /Applications/DarwinPorts \
      /Applications/MacPorts \
      /Library/LaunchDaemons/org.macports.* \
      /Library/Receipts/DarwinPorts*.pkg \
      /Library/Receipts/MacPorts*.pkg \
      /Library/StartupItems/DarwinPortsStartup \
      /Library/Tcl/darwinports1.0 \
      /Library/Tcl/macports1.0 \
      ~/.macports
fi
