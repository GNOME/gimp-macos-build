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

pushd ~/macports-gimp${VGIMP}-arm64/var/macports/build/_Users_$(whoami)_project_ports_graphics_gegl/gegl/work/build
  # needed to find vapigen
  export PATH=/Users/lukasoberhuber/macports-gimp${VGIMP}-arm64/bin:$PATH
  ~/macports-gimp${VGIMP}-arm64/bin/ninja -j10 -v
  ~/macports-gimp${VGIMP}-arm64/bin/ninja install
popd
