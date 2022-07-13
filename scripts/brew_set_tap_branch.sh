#!/usr/bin/env bash
#####################################################################
 # brew_set_tap_branch.sh: during development, sets homebrew-gimp   #
 #                         branch to the current branch             #
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

PREFIX=$HOME/homebrew
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $SCRIPT_DIR
CURRENT_BRANCH=$(git branch --show-current)
popd

TAP_LOCATION="${PREFIX}/Library/Taps/infrastructure/homebrew-gimp"

if [ "$CURRENT_BRANCH" != "master" ]
then
  if [ -d "${TAP_LOCATION}" ]
  then
    pushd "${PREFIX}/Library/Taps/infrastructure/homebrew-gimp"
    git stash
    git co $CURRENT_BRANCH
    git stash pop
    popd
  else
    echo "ERROR: cannot switch to current branch as tap does not exist"
    exit 1
  fi
fi
