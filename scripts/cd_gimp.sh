#!/usr/bin/env bash
####################################################################
# cd_gimp.sh: goes to gimp source dir                              #
#                                                                  #
# Copyright 2023 Lukas Oberhuber <lukaso@gmail.com>                #
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

if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${(%):-%x}" ]; then
    SCRIPT_PATH="${(%):-%x}"
else
    echo "Error: Unable to determine script path."
    return 1 2>/dev/null || exit 1
fi

SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" >/dev/null 2>&1 && pwd)"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Usage: \`. $0\` otherwise does not change directory"
fi

TARGET_DIR="$("${SCRIPT_DIR}/gimp_dir.sh")"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: target directory '$TARGET_DIR' doesn't exists."
    return 1 2>/dev/null || exit 1
fi

cd "$TARGET_DIR"

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "Changed directory to: $TARGET_DIR"
fi
