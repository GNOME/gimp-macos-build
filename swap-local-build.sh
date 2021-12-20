#!/usr/bin/env bash
 ####################################################################
 # swap-local-build.sh: swaps out local build directories           #
 #                                                                  #
 # Copyright 2021 Lukas Oberhuber <lukaso@gmail.com>                #
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

function pure_version() {
	echo '0.1'
}

function version() {
	echo "swap-local-build.sh $(pure_version)"
}


function usage() {
	version
	echo "Swap out jhbuild directories."
	echo "Usage:  $(basename $0) [options]"
	echo "The jhbuild cache and the gtk source and installation directories will"
	echo "be swapped into a backup position, and the new directories copied in"
  echo "if they exist."
  echo "The function will do nothing if the option set is already current."
	echo "Options:"
	echo "  --gimp210"
	echo "      switch to gimp 2.10 and swap out current (if needed)"
	echo "  --gimp299"
	echo "      switch to gimp 2.99 and swap out current (if needed)"
	echo "  --status"
	echo "      what is the current local build"
  echo "  --force-current folder_path"
  echo "      if current is incorrect or not set, sets current without making changes"
	echo "  --folder folder_path"
	echo "      switch to main build being folder_path and swap out current if needed"
	echo "  --version         show tool version number"
	echo "  -h, --help        display this help"
	exit 0
}

STATUS=''
FORCE_CURRENT=''

while test "${1:0:1}" = "-"; do
	case $1 in
	--gimp210)
		FUTURE_EXT="gimp210"
		shift;;
	--gimp299)
		FUTURE_EXT="gimp299"
		shift;;
	--status)
		STATUS="true"
		shift;;
	--force-current)
    FORCE_CURRENT="true"
		FUTURE_EXT=$2
		shift; shift;;
	--folder)
		FUTURE_EXT=$2
		shift; shift;;
	-h | --help)
		usage;;
	--version)
		version; exit 0;;
	-*)
		echo "Unknown option $1. Run with --help for help."
		exit 1;;
	esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CACHE_EXT="jhbuild"
CACHE_BASE="${HOME}/.cache"
CACHE_DIR="${CACHE_BASE}/${CACHE_EXT}"

BUILD_EXT="gtk"
BUILD_BASE="${HOME}"
BUILD_DIR="${BUILD_BASE}/${BUILD_EXT}"

SAVE_DIR="${HOME}/.gimp_build_save"
CURRENT_VERSION="${SAVE_DIR}/current_version"

mkdir -p ${SAVE_DIR}

# Get current version
if [ -f "${CURRENT_VERSION}" ]; then
  CURRENT_EXT="$(head -1 "${CURRENT_VERSION}")"
fi

if [ ! -z "${STATUS}" ]; then
  echo "Current: ${CURRENT_EXT}"
  exit 0;
fi

if [ -z "${CURRENT_EXT}" ]; then
  CURRENT_EXT="unknown"
fi

if [ "${CURRENT_EXT}" = "${FUTURE_EXT}" ]; then
  echo "Not changing folders. Already on ${CURRENT_EXT}"
  exit 0
fi

# Put new version
echo "${FUTURE_EXT}" > "${CURRENT_VERSION}"

if [ ! -z "${FORCE_CURRENT}" ]; then
  echo "Current set to: ${FUTURE_EXT}"
  exit 0;
fi

echo "Moving .cache/jhbuild and gtk to ${CURRENT_EXT}"
if [ -d "${SAVE_DIR}/${CURRENT_EXT}/${CACHE_EXT}" ]; then
  echo "First removing existing backup of ${CACHE_EXT}"
  rm -rf "${SAVE_DIR}/${CURRENT_EXT}/${CACHE_EXT}"
fi

if [ -d "${SAVE_DIR}/${CURRENT_EXT}/${BUILD_EXT}" ]; then
  echo "First removing existing backup of ${BUILD_EXT}"
  rm -rf "${SAVE_DIR}/${CURRENT_EXT}/${BUILD_EXT}"
fi

if [ -d "${CACHE_DIR}" ] && [ -d "${BUILD_DIR}" ]; then
  echo "Moving out ${CACHE_DIR} and ${BUILD_DIR} to ${CURRENT_EXT}"
  mkdir -p "${SAVE_DIR}/${CURRENT_EXT}"
  mv "${CACHE_DIR}" "${SAVE_DIR}/${CURRENT_EXT}"
  mv "${BUILD_DIR}" "${SAVE_DIR}/${CURRENT_EXT}"
else
  echo "${CACHE_DIR} and/or ${BUILD_DIR} not present"
fi

if [ -d "${SAVE_DIR}/${FUTURE_EXT}/${CACHE_EXT}" ] && [ -d "${SAVE_DIR}/${FUTURE_EXT}/${BUILD_EXT}" ]; then
  echo "Moving ${FUTURE_EXT} to .cache/jhbuild and gtk"
  mv "${SAVE_DIR}/${FUTURE_EXT}/${CACHE_EXT}" "${CACHE_BASE}"
  mv "${SAVE_DIR}/${FUTURE_EXT}/${BUILD_EXT}" "${BUILD_BASE}"
else
  echo "${FUTURE_EXT} is not present"
fi
