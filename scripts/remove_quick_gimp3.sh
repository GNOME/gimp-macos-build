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


arch=$(uname -m)
echo "*** Build: $arch"
source ~/.profile-gimp-${arch}

if [ -z "$GIMP_PREFIX" ]; then
  export GIMP_PREFIX=${HOME}/macports-gimp3-${arch}
fi
export PATH=$GIMP_PREFIX/bin:$PATH

pushd $GIMP_PREFIX
  rm bin/gimp*
  rm -r etc/gimp
  rm -r lib/gimp
  rm -r share/gimp
  rm -r var/gimp
  rm -r include/gimp-*
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
