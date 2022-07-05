#!/usr/bin/env bash
#####################################################################
 # macports_uninstall.sh: installs macports                         #
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

PREFIX=$HOME/macports

INSTALLDIR=$HOME

pushd "${INSTALLDIR}"

if [ ! -d "MacPorts-2.7.2" ]
then
    curl -L https://github.com/macports/macports-base/releases/download/v2.7.2/MacPorts-2.7.2.tar.bz2 > MacPorts-2.7.2.tar.bz2
    tar xjvf MacPorts-2.7.2.tar.bz2
fi

pushd MacPorts-2.7.2

# NOTE: Both patches can be removed on next release of MacPorts
# Currently required to get cmake-bootstrap to build:
# https://trac.macports.org/ticket/65313
if [ ! -f "macports.patch" ]
then
  curl -L https://github.com/macports/macports-base/commit/fbfcb9ff67ae55f477652fe6b7e7fc809782dbbf.patch > macports.patch
  patch -p1 < macports.patch
fi
if [ ! -f "macports2.patch" ]
then
  curl -L https://github.com/macports/macports-base/commit/a594e01e3cfffe66c2d7219e10ebe0bb1a6da4ea.patch > macports2.patch
  patch -p1 < macports2.patch
fi

./configure --prefix=$PREFIX \
  --with-no-root-privileges \
  --with-install-user=$USER \
  --with-applications-dir=${PREFIX}/Applications \
  --without-startupitems
make
make install
# env vars will not set in the parent shell
export PATH=$PREFIX/bin:$PATH
echo '-x11 +no_x11 +quartz -python27' >> $PREFIX/etc/macports/variants.conf
echo 'macosx_deployment_target 11.0' >> $PREFIX/etc/macports/macports.conf
export MACOSX_DEPLOYMENT_TARGET=11.0

echo "*** Setup 11.3 SDK"

pushd /Library/Developer/CommandLineTools/SDKs
if [ ! -d "MacOSX11.3.sdk" ]
then
    sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz' | sudo tar -xzf -
fi
popd
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX11.3.sdk

port -v selfupdate

popd # MacPorts-2.7.2
# rm -rf MacPorts-2.7.2*

popd # INSTALLDIR
