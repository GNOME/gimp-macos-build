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

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
PREFIX=/opt/local
export PATH=$PREFIX/bin:$PATH

export MACOSX_DEPLOYMENT_TARGET=11.0

port -N install icu
port -N install lcms2 libunistring gmp nettle libtasn1 gnutls jpeg readline python2 glib-networking openjpeg  gtk-mac-integration-gtk2 poppler poppler-data
port -N install json-glib p2tc exiv2 gexiv2 ilmbase openexr libwebp libcroco librsvg-24 json-c
port -N install libmypaint mypaint-brushes libde265 nasm x265 libheif aalib shared-mime-info iso-codes libwmf libmng ghostscript
port -N install pycairo pygobject pygtk gtk-mac-integration-gtk2-python
port -N install enchant libpsl sqlite vala gnutls
port -N install SuiteSparse_AMD SuiteSparse_CAMD SuiteSparse_CCOLAMD SuiteSparse_COLAMD SuiteSparse_CHOLMOD \
  SuiteSparse_UMFPACK metis
port -N install libsoup
port -N install babl gegl
