#!/usr/bin/env bash
#####################################################################
 # macports_install_packages.sh: installs gimp dependencies         #
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

function pure_version() {
	echo '0.1'
}

function version() {
	echo "macports_install_packages.sh $(pure_version)"
}

function usage() {
    version
    echo ""
    echo "Builds Gimp 3 dependencies."
    echo "Usage:  $(basename $0) [options]"
    echo ""
    echo "Builds Gimp dependencies."
    echo "By default builds dependencies, end to end."
    echo "For CI builds, can be split into steps to reduce run time for each"
    echo "step."
    echo "Options:"
    echo "  --circleci"
    echo "      settings for circleci instead of local"
    echo "  --part1"
    echo "      first part. Each part takes up to 3 hours on circleci"
    echo "  --part2"
    echo "      second part."
    echo "  --part3"
    echo "      third part."
    echo "  --part4"
    echo "      currently a no op"
    echo "  --part5"
    echo "      currently a no op"
    echo "  --version         show tool version number"
    echo "  -h, --help        display this help"
    exit 0
}

circleci=''
PART1="true"
PART2="true"
PART3="true"
PART4="true"
PART5="true"

while test "${1:0:1}" = "-"; do
	case $1 in
	--circleci)
		circleci="true"
		shift;;
	--part1)
		PART2=''
		PART3=''
		PART4=''
		PART5=''
		shift;;
	--part2)
		PART1=''
		PART3=''
		PART4=''
		PART5=''
		shift;;
	--part3)
		PART1=''
		PART2=''
		PART4=''
		PART5=''
		shift;;
	--part4)
		PART1=''
		PART2=''
		PART3=''
		PART5=''
		shift;;
	--part5)
		PART1=''
		PART2=''
		PART3=''
		PART4=''
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

function massage_output() {
	if [ $circleci ]; then
    # suppress progress bar
    "$@" | cat
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then exit "${PIPESTATUS[0]}"; fi
  else
    "$@"
  fi
}

function port_install() {
  massage_output $dosudo port -N install "$@"
}

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source ~/.profile
export PATH=$PREFIX/bin:$PATH

if [ ! -z "${PART1}" ]; then
  # Have to clean every port because sub-ports get gummed up when they fail to
  # build/install. It would require detecting failure (obscure long error like
  # this): Error: See /opt/local/var/macports/logs/_opt_local_var_macports_sources_rsync.macports.org_macports_release_tarballs_ports_devel_dbus/dbus/main.log for details.
  $dosudo port clean python310
  port_install python310
  $dosudo port select --set python python310
  $dosudo port select --set python3 python310
  $dosudo port clean \
                icu \
                openjpeg \
                ilmbase \
                json-c \
                libde265 \
                nasm \
                x265 \
                util-linux \
                xmlto \
                py-cairo \
                py-gobject3 \
                gtk-osx-application-gtk3 \
                libarchive \
                libyaml \
                lcms2 \
                glib-networking \
                poppler -boost \
                poppler-data \
                fontconfig \
                libmypaint \
                mypaint-brushes1 \
                libheif \
                aalib \
                webp \
                shared-mime-info \
                iso-codes \
                librsvg \
                gexiv2 \
                libwmf \
                openexr \
                libmng \
                ghostscript
  port_install  icu \
                openjpeg \
                ilmbase \
                json-c \
                libde265 \
                nasm \
                x265 \
                util-linux \
                xmlto \
                py-cairo \
                py-gobject3 \
                gtk-osx-application-gtk3 \
                libarchive \
                libyaml \
                lcms2 \
                glib-networking \
                poppler -boost \
                poppler-data \
                fontconfig \
                libmypaint \
                mypaint-brushes1 \
                libheif \
                aalib \
                webp \
                shared-mime-info \
                iso-codes \
                librsvg \
                gexiv2 \
                libwmf \
                openexr \
                libmng \
                ghostscript
fi

if [ ! -z "${PART2}" ]; then
  $dosudo port clean          rust \
                              llvm-15
  # Must be verbose because otherwise times out on circle ci
  $dosudo port -v -N install  rust \
                              llvm-15
fi

if [ ! -z "${PART3}" ]; then
  $dosudo port clean         clang-15
  $dosudo port -v -N install clang-15

  echo "gcc12 being installed before gegl and gjs (via mozjs91)"
  $dosudo sed -i -e 's/buildfromsource always/buildfromsource never/g' /opt/local/etc/macports/macports.conf
  $dosudo port clean gcc12
  port_install gcc12
  $dosudo sed -i -e 's/buildfromsource never/buildfromsource always/g' /opt/local/etc/macports/macports.conf

  $dosudo port clean dbus
  port_install -f dbus
  $dosudo port clean \
                gjs \
                adwaita-icon-theme \
                babl \
                gegl +vala
  port_install  gjs \
                adwaita-icon-theme \
                babl \
                gegl +vala
  # 10.12 requires git to be installed, and perl doesn't build
  port_install p5.34-io-compress-brotli build.jobs=1
  if [ $circleci ]; then
    $dosudo port clean git
    port_install git -perl5_34
  fi

  $dosudo port -v -N upgrade outdated
fi

if [ ! -z "${PART4}" ]; then
  echo "**** No op"
fi

if [ ! -z "${PART5}" ]; then
  echo "**** No op"
fi
