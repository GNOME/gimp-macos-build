#!/usr/bin/env bash
####################################################################
# macports1_install_packages.sh: installs gimp dependencies        #
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

# How to get a pre-built binary (but beware of dependencies):

  # echo "about to build DESIRED_DEPENDENCY dependencies"
  # deps=$(port deps DESIRED_DEPENDENCY | awk '/Library Dependencies:/ {for (i=3; i<=NF; i++) print $i}' ORS=" " | tr ',' ' ')
  # port_clean_and_install $deps

  # sed -i -e 's/buildfromsource always/buildfromsource ifneeded/g' ${GIMP_PREFIX}/etc/macports/macports.conf
  # sed -i -e 's/macosx_deployment_target/#macosx_deployment_target/g' ${GIMP_PREFIX}/etc/macports/macports.conf
  # sed -i -e 's/macosx_sdk_version/#macosx_sdk_version/g' ${GIMP_PREFIX}/etc/macports/macports.conf
  # (
  #   unset MACOSX_DEPLOYMENT_TARGET
  #   unset SDKROOT
  #   port_clean_and_install \
  #     DESIRED_DEPENDENCY
  # )
  # sed -i -e 's/buildfromsource ifneeded/buildfromsource always/g' ${GIMP_PREFIX}/etc/macports/macports.conf
  # sed -i -e 's/#macosx_deployment_target/macosx_deployment_target/g' ${GIMP_PREFIX}/etc/macports/macports.conf
  # sed -i -e 's/#macosx_sdk_version/macosx_sdk_version/g' ${GIMP_PREFIX}/etc/macports/macports.conf

set -e

function pure_version() {
  echo '0.2'
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
  echo "      second part"
  echo "  --part3"
  echo "      third part"
  echo "  --part4"
  echo "      fourth part"
  echo "  --part5"
  echo "      currently a no op"
  echo "  --only-package <package>"
  echo "      only install named package. Most useful for testing"
  echo "  --uninstall-package <package>"
  echo "      uninstall named package. Useful if needed to clear things out."
  echo "      This will force uninstall regardless of dependencies"
  echo "  --port-edit-package <package>"
  echo "      open the Portfile of the package"
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
    shift
    ;;
  --part2)
    PART1=''
    PART3=''
    PART4=''
    PART5=''
    shift
    ;;
  --part3)
    PART1=''
    PART2=''
    PART4=''
    PART5=''
    shift
    ;;
  --part4)
    PART1=''
    PART2=''
    PART3=''
    PART5=''
    shift
    ;;
  --part5)
    PART1=''
    PART2=''
    PART3=''
    PART4=''
    shift
    ;;
  --only-package)
    ONLY_PACKAGE=$2
    shift 2
    ;;
  --uninstall-package)
    UNINSTALL_PACKAGE=$2
    shift 2
    ;;
  --port-edit-package)
    PORT_EDIT_PACKAGE=$2
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  --version)
    version
    exit 0
    ;;
  -*)
    echo "Unknown option $1. Run with --help for help."
    exit 1
    ;;
  esac
done

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

arch=$(uname -m)
echo "*** Build: $arch"
source ~/.profile-gimp-${arch}

if [ -z "$GIMP_PREFIX" ]; then
  export GIMP_PREFIX=${HOME}/macports-gimp3-${arch}
fi
export PATH=$GIMP_PREFIX/bin:$PATH

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
  massage_output port -k -N install "$@"
}

function port_clean_and_install() {
  echo "cleaning and installing $*"
  port clean "$@"
  port_install "$@"
}

# Must be verbose because otherwise times out on circle ci
function port_long_clean_and_install() {
  port clean "$@"
  port -v -N install "$@"
}

# * uninstall because if not, then get a failure on building
# * clean because if not, then get random failure
# * uninstall -f to avoid:
#   "Note: It is not recommended to uninstall/deactivate a port that has dependents as it breaks the dependents.
#    The following ports will break: libgcc @6.0_0
#    Continue? [y/N]:
#    Too long with no output (exceeded 30m0s): context deadline exceeded"
function port_force_uninstall_and_clean() {
  echo "force uninstalling and cleaning $*"
  port -N uninstall -f "$@" || true
  port -N clean "$@" || true
}

# for xargs support
export -f port_install
export -f port_clean_and_install
export -f massage_output

echo "**** Debugging info ****"
echo "**** installed ports ****"
port installed
echo ""
echo ""
echo "**** Configuration ****"
echo ">> macports.conf"
cat ${GIMP_PREFIX}/etc/macports/macports.conf
echo ""
echo ""
echo ">> variants.conf"
cat ${GIMP_PREFIX}/etc/macports/variants.conf
echo ""
echo ""
echo ">> sources.conf"
cat ${GIMP_PREFIX}/etc/macports/sources.conf
echo ""
echo ""
echo "**** End Debugging info ****"

if [ -n "${ONLY_PACKAGE}" ]; then
  port_clean_and_install "${ONLY_PACKAGE}"
  exit 0
fi

if [ -n "${UNINSTALL_PACKAGE}" ]; then
  port_force_uninstall_and_clean "${UNINSTALL_PACKAGE}"
  exit 0
fi

if [ -n "${PORT_EDIT_PACKAGE}" ]; then
  port edit "${PORT_EDIT_PACKAGE}"
  exit 0
fi

if [ -n "${PART1}" ]; then
  # ** Reinstate these uninstalls if builds fail
  # temporarily uninstall gegl, gimp3, libgcc12 (until all builds are fixed)
  # All of these ports at some point failed to upgrade, build or otherwise cooperate
  # unless uninstalled, even when being built from scratch.
  port_force_uninstall_and_clean gimp-official
  port_force_uninstall_and_clean babl gegl
  # port_force_uninstall_and_clean gcc12
  # * libgcc12 because it is a dependency of gcc12 and if not also uninstalled, gcc12 build sometimes fails
  # port_force_uninstall_and_clean libgcc12

  # ** Can be removed once run once on master
  # xxx

  port_clean_and_install cmake

  # Former part 2, but Circle CI now allows much longer builds (5 hours)
  port_force_uninstall_and_clean p5.34-io-compress-brotli
  port_force_uninstall_and_clean p5.34-http-message
  # port_clean_and_install p5.34-io-compress-brotli build.jobs=1

  port_long_clean_and_install rust
  port_clean_and_install x265 +highdepth
fi

if [ -n "${PART2}" ]; then
  # Have to clean every port because sub-ports get gummed up when they fail to
  # build/install. It would require detecting failure (obscure long error like
  # this): Error: See ${GIMP_PREFIX}/var/macports/logs/_opt_local_var_macports_sources_rsync.macports.org_macports_release_tarballs_ports_devel_dbus/dbus/main.log for details.

  # Need to know correct python version so py-cairo and py-gobject3 are installed in correct version (there are
  # multiple versions of python installed due to myriad macports dependencies we don't control)
  port_clean_and_install python${PYTHON_SHORT_VERSION}
  port select --set python python${PYTHON_SHORT_VERSION}
  port select --set python3 python${PYTHON_SHORT_VERSION}

 # Install py-cairo and py-gobject3 explicitly first to ensure 'gi' module is available
  port_clean_and_install py${PYTHON_SHORT_VERSION}-cairo
  port_clean_and_install py${PYTHON_SHORT_VERSION}-gobject3

  port_clean_and_install \
    aalib \
    cfitsio \
    ffmpeg \
    fontconfig \
    gexiv2 \
    ghostscript \
    git \
    glib-networking \
    gtk3 \
    icu \
    iso-codes \
    json-c \
    lcms2 \
    libde265 \
    libheif \
    libjxl \
    libmng \
    libmypaint \
    librsvg \
    libwmf \
    libyaml \
    mypaint-brushes1 \
    nasm \
    openexr \
    openjpeg \
    poppler -boost \
    poppler-data \
    py-cairo \
    py-gobject3 \
    qoi \
    shared-mime-info \
    util-linux \
    webp \
    xmlto

  # required for `realpath` command which is used in GIMP build
  port_clean_and_install coreutils
fi

if [ -n "${PART3}" ]; then
  port_long_clean_and_install clang-16
fi

if [ -n "${PART4}" ]; then
  echo "gcc being installed before gegl"

  port_long_clean_and_install gcc14

  # Now we can install libgcc
  port_long_clean_and_install libgcc

  port_clean_and_install \
    libomp -debug
  port clean libgcc

  port_clean_and_install \
    jdupes

  port clean dbus
  port_install -f dbus
  port_clean_and_install \
    adwaita-icon-theme
  port_clean_and_install \
    babl \
    gegl +vala
  if [ $circleci ]; then
    port clean git
    port_install git -perl5_34
  fi

  echo "**** Outdated ports"
  port outdated

  echo "**** Upgrading outdated ports"
  # Must be verbose because otherwise times out on circle ci
  port -v -N upgrade outdated || true
  port -N uninstall inactive || true
fi

if [ -n "${PART5}" ]; then
  echo "**** No op"
fi
