#!/usr/bin/env bash
#####################################################################
 # macports1_install_packages.sh: installs gimp dependencies         #
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
	echo "macports1_install_packages.sh $(pure_version)"
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
    echo "  --only-package <package>"
    echo "      only install named package. Most useful for testing"
    echo "  --uninstall-package <package>"
    echo "      uninstall named package. Useful if needed to clear things out."
    echo "      This will force uninstall regardless of dependencies."
    echo "  --version         show tool version number"
    echo "  -h, --help        display this help"
    exit 0
}

PART1="true"
PART2="true"
PART3="true"
PART4="true"
PART5="true"

while test "${1:0:1}" = "-"; do
	case $1 in
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
  --only-package)
    ONLY_PACKAGE=$2
    shift 2;;
  --uninstall-package)
    UNINSTALL_PACKAGE=$2
    shift 2;;
	-h | --help)
		usage;;
	--version)
		version; exit 0;;
	-*)
		echo "Unknown option $1. Run with --help for help."
		exit 1;;
	esac
done

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source ~/.profile
export PATH=$PREFIX/bin:$PATH

function massage_output() {
	if [ -n "$circleci" ]; then
    # suppress progress bar
    "$@" | cat
    status="${PIPESTATUS[0]}"
    if [ "${status}" -ne 0 ]; then exit "${status}"; fi
  else
    "$@"
  fi
}

function port_install() {
  massage_output $dosudo port -k -N install "$@"
}

function port_clean_and_install() {
  $dosudo port clean "$@"
  port_install "$@"
}

echo "**** Debugging info ****"
echo "**** installed ports ****"
port installed
echo ""
echo ""
echo "**** Configuration ****"
echo ">> macports.conf"
cat ${PREFIX}/etc/macports/macports.conf
echo ""
echo ""
echo ">> variants.conf"
cat ${PREFIX}/etc/macports/variants.conf
echo ""
echo ""
echo ">> sources.conf"
cat ${PREFIX}/etc/macports/sources.conf
echo ""
echo ""
echo "**** End Debugging info ****"

if [ -n "${ONLY_PACKAGE}" ]; then
  port_clean_and_install "${ONLY_PACKAGE}"
  exit 0
fi

if [ -n "${UNINSTALL_PACKAGE}" ]; then
  $dosudo port -f uninstall "${UNINSTALL_PACKAGE}"
  exit 0
fi

if [ -n "${PART1}" ]; then
  echo "force remove broken port - can be removed once all versions are on master and gimp-2-10"
  $dosudo port -f uninstall openblas @0.3.21_2+gcc12+lapack || true
  echo "build cmake dependencies in case they are needed for gimp"
  port_clean_and_install  libcxx \
                          curl \
                          expat \
                          zlib \
                          bzip2 \
                          libarchive \
                          ncurses \
                          libuv
  echo "cmake-bootstrap being installed since won't build from source with 10.12 SDK"
  $dosudo sed -i -e 's/buildfromsource always/buildfromsource ifneeded/g' /opt/local/etc/macports/macports.conf
  port_clean_and_install cmake
  $dosudo sed -i -e 's/buildfromsource ifneeded/buildfromsource always/g' /opt/local/etc/macports/macports.conf
fi

if [ -n "${PART2}" ]; then
  port_clean_and_install p5.34-io-compress-brotli build.jobs=1
  $dosudo port clean          rust \
                              llvm-15
  # Must be verbose because otherwise times out on circle ci
  $dosudo port -v -N install  rust \
                              llvm-15
fi

if [ -n "${PART3}" ]; then
  # Have to clean every port because sub-ports get gummed up when they fail to
  # build/install. It would require detecting failure (obscure long error like
  # this): Error: See /opt/local/var/macports/logs/_opt_local_var_macports_sources_rsync.macports.org_macports_release_tarballs_ports_devel_dbus/dbus/main.log for details.
  # $dosudo port clean python310
  # port_install python310
  # $dosudo port select --set python python310
  # $dosudo port select --set python3 python310
  port_clean_and_install \
                aalib \
                appstream-glib \
                exiv2 \
                git \
                gexiv2 \
                ghostscript \
                glib-networking \
                gnutls \
                gtk-osx-application-gtk2 \
                gtk2 \
                ilmbase \
                iso-codes \
                lcms2 \
                libde265 \
                libheif \
                libjpeg-turbo \
                libjxl \
                libmng \
                libmypaint \
                libpsl \
                libraw \
                librsvg \
                libtasn1 \
                libunistring \
                libwmf \
                mypaint-brushes1 \
                nasm \
                nettle \
                openexr \
                openjpeg \
                openssl \
                poly2tri-c \
                poppler -boost \
                poppler-data \
                python27 \
                readline \
                shared-mime-info \
                vala \
                webp \
                x265
fi

if [ -n "${PART4}" ]; then
  $dosudo port clean         clang-16
  $dosudo port -v -N install clang-16

  echo "gcc12 being installed before gegl"
  # libomp can't handle +debug variant as prebuilt binary
  $dosudo sed -i -e 's/buildfromsource always/buildfromsource ifneeded/g' /opt/local/etc/macports/macports.conf
  port_clean_and_install \
                libomp -debug \
                gcc12
  $dosudo sed -i -e 's/buildfromsource ifneeded/buildfromsource always/g' /opt/local/etc/macports/macports.conf

  # $dosudo port clean dbus
  # port_install -f dbus
  port_clean_and_install \
                adwaita-icon-theme \
                babl \
                gegl +vala
  if [ $circleci ]; then
    $dosudo port clean git
    port_install git -perl5_34
  fi

  $dosudo port -v -N upgrade outdated
  $dosudo port uninstall inactive || true
fi

if [ -n "${PART5}" ]; then
  echo "**** No op"
fi
