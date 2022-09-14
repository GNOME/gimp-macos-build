#!/usr/bin/env bash
#####################################################################
 # conda_uninstall.sh: uninstalls conda                             #
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

# if [[ $(uname -m) == 'arm64' ]]; then
#   build_arm64=true
#   echo "*** Build: arm64"
#   PREFIX=$HOME/homebrew
#   OTHEER_PREFIX=$HOME/homebrew_x86_64
# else
#   build_arm64=false
#   echo "*** Build: x86_64"
#   PREFIX=$HOME/homebrew_x86_64
#   OTHER_PREFIX=$HOME/homebrew
# fi

# rm -rf $PREFIX
# # Don't delete caches until both prefixes are deleted
# if [ ! -d "$OTHER_PREFIX" ]
# then
#   rm -rf $HOME/Library/Caches/Homebrew
# fi

rm -rf $HOME/miniconda
rm -rf $HOME/.condarc $HOME/.conda $HOME/.continuum