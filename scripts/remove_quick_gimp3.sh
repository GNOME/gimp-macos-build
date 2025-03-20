#!/usr/bin/env bash
#####################################################################
 # quick_rebuild.sh: Builds gimp locally once full build complete   #
 #                                                                  #
 # Copyright 2023-2025 Lukas Oberhuber <lukaso@gmail.com>           #
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

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

pushd ~/macports-gimp${VGIMP}-${arch}
  rm bin/gimp*
  rm -r etc/gimp
  rm -r lib/gimp
  rm -r share/gimp
  rm -r var/gimp
  rm -r include/gimp-3.0
  rm -r lib/girepository-1.0/Gimp*
  rm -r lib/libgimp*
  rm -r lib/pkgconfig/gimp*
  rm -r share/man/man5/gimp*
  rm -r share/man/man1/gimp*
  rm share/locale/*/LC_MESSAGES/gimp*
  rm share/icons/hicolor/*/apps/gimp*
  rm share/applications/gimp*
  rm share/gir-1.0/Gimp*
  rm share/metainfo/org.gimp.GIMP.appdata.xml
  rm -r share/gimp
popd || exit
