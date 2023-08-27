#!/usr/bin/env bash
#####################################################################
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

set -e

export VGIMP=3

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

source ~/.profile-gimp${VGIMP}
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
  echo "cleaning and installing $@"
  $dosudo port clean "$@"
  port_install "$@"
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

if [ -n "${PORT_EDIT_PACKAGE}" ]; then
  port edit "${PORT_EDIT_PACKAGE}"
  exit 0
fi

if [ -n "${PART1}" ]; then
  # ** Reinstate these uninstalls if builds fail
  # temporarily uninstall gegl, gimp3, libgcc12 (until all builds are fixed)
  # All of these ports at some point failed to upgrade, build or otherwise cooperate
  # unless uninstalled, even when being built from scratch.
  # $dosudo port uninstall gimp3 || true
  # $dosudo port uninstall -f gegl || true
  # $dosudo port uninstall -f gcc12 || true
  # $dosudo port uninstall -f libgcc12 || true
  # $dosudo port uninstall -f appstream-glib || true
  # $dosudo port clean appstream-glib || true

  # Can be removed once run once on master
  # xxx

  echo "build cmake dependencies in case they are needed for gimp"
  port_clean_and_install libcxx \
    curl \
    expat \
    zlib \
    bzip2 \
    libarchive \
    ncurses \
    libuv
  echo "cmake-bootstrap being installed since won't build from source with 10.13 SDK"
  $dosudo sed -i -e 's/buildfromsource always/buildfromsource ifneeded/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/macosx_deployment_target/#macosx_deployment_target/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/macosx_sdk_version/#macosx_sdk_version/g' ${PREFIX}/etc/macports/macports.conf
  (
    # temporarily unset deployment targets since cmake does not build with 10.13 SDK
    # and we don't really care since only used at build time
    # Can be removed once https://trac.macports.org/ticket/66953 is fixed
    unset MACOSX_DEPLOYMENT_TARGET
    unset SDKROOT
    echo "clean cmake****"
    $dosudo port clean cmake
    $dosudo port -k -N install cmake
  )
  $dosudo sed -i -e 's/buildfromsource ifneeded/buildfromsource always/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/#macosx_deployment_target/macosx_deployment_target/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/#macosx_sdk_version/macosx_sdk_version/g' ${PREFIX}/etc/macports/macports.conf

  # Former part 2, but Circle CI now allows much longer builds (5 hours)

  port_clean_and_install p5.34-io-compress-brotli build.jobs=1
  echo "about to build rust dependencies"
  rust_deps=$(port deps rust | awk '/Library Dependencies:/ {for (i=3; i<=NF; i++) print $i}' ORS=" " | tr ',' ' ')
  port_clean_and_install $rust_deps
  # Build only dependency, so don't care if backward compatible
  echo "install rust"
  $dosudo sed -i -e 's/buildfromsource always/buildfromsource ifneeded/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/macosx_deployment_target/#macosx_deployment_target/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/macosx_sdk_version/#macosx_sdk_version/g' ${PREFIX}/etc/macports/macports.conf
  (
    unset MACOSX_DEPLOYMENT_TARGET
    unset SDKROOT
    $dosudo port clean rust
    # Must be verbose because otherwise times out on circle ci
    $dosudo port -v -N install rust
  )
  $dosudo sed -i -e 's/buildfromsource ifneeded/buildfromsource always/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/#macosx_deployment_target/macosx_deployment_target/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/#macosx_sdk_version/macosx_sdk_version/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo port clean llvm-15
  # Must be verbose because otherwise times out on circle ci
  $dosudo port -v -N install llvm-15
fi

if [ -n "${PART2}" ]; then
  # Can remove once on master
  $dosudo port uninstall -f libstemmer || true
  port_clean_and_install libstemmer || true

  # Have to clean every port because sub-ports get gummed up when they fail to
  # build/install. It would require detecting failure (obscure long error like
  # this): Error: See ${PREFIX}/var/macports/logs/_opt_local_var_macports_sources_rsync.macports.org_macports_release_tarballs_ports_devel_dbus/dbus/main.log for details.
  port_clean_and_install python310
  $dosudo port select --set python python310
  $dosudo port select --set python3 python310
  port_clean_and_install \
    icu \
    openjpeg \
    git \
    json-c \
    libde265 \
    nasm \
    x265 \
    util-linux \
    xmlto \
    py-cairo \
    py-gobject3 \
    gtk3 \
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

if [ -n "${PART3}" ]; then
  $dosudo port clean clang-16
  $dosudo port -v -N install clang-16
fi

if [ -n "${PART4}" ]; then
  echo "gcc12 being installed before gegl"

  # libgcc12 is installed with GIMP so must be set for 10.13
  # Uninstall once
  $dosudo port uninstall -f libgcc12 || true
  $dosudo port clean libgcc12
  # $dosudo port uninstall -f gcc12 || true
  $dosudo port clean gcc12
  $dosudo port -v -N install \
    libgcc12

  # libomp can't handle +debug variant as prebuilt binary
  $dosudo sed -i -e 's/buildfromsource always/buildfromsource ifneeded/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/macosx_deployment_target/#macosx_deployment_target/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/macosx_sdk_version/#macosx_sdk_version/g' ${PREFIX}/etc/macports/macports.conf
  (
    unset MACOSX_DEPLOYMENT_TARGET
    unset SDKROOT
    port_clean_and_install \
      libomp -debug
    # * uninstall because if not, then get a failure on building
    # * clean because if not, then get random failure
    # * uninstall -f to avoid:
    #   "Note: It is not recommended to uninstall/deactivate a port that has dependents as it breaks the dependents.
    #    The following ports will break: libgcc @6.0_0
    #    Continue? [y/N]:
    #    Too long with no output (exceeded 30m0s): context deadline exceeded"
    # * libgcc12 because it is a dependency of gcc12 and if not also uninstalled, gcc12 build sometimes fails
    # $dosudo port uninstall -f libgcc12 || true
    $dosudo port clean libgcc12
    # $dosudo port uninstall -f gcc12 || true
    $dosudo port clean gcc12
    $dosudo port -v -N install \
      libgcc12 \
      gcc12
    # broken build on x86_64 and is a build only dependency
    # https://trac.macports.org/ticket/68041
    port_clean_and_install \
      jdupes
  )
  $dosudo sed -i -e 's/buildfromsource ifneeded/buildfromsource always/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/#macosx_deployment_target/macosx_deployment_target/g' ${PREFIX}/etc/macports/macports.conf
  $dosudo sed -i -e 's/#macosx_sdk_version/macosx_sdk_version/g' ${PREFIX}/etc/macports/macports.conf

  $dosudo port clean dbus
  port_install -f dbus
  port_clean_and_install \
    adwaita-icon-theme \
    babl \
    gegl +vala
  if [ $circleci ]; then
    $dosudo port clean git
    port_install git -perl5_34
  fi

  echo "**** Outdated ports"
  port outdated

  $dosudo port -v -N upgrade outdated || true
  $dosudo port uninstall inactive || true
fi

if [ -n "${PART5}" ]; then
  echo "**** No op"
fi
