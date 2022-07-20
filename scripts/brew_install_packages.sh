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

PREFIX=$HOME/homebrew

source $PREFIX/.profile

echo $SDKROOT
echo $MACOSX_DEPLOYMENT_TARGET
echo $PATH
which brew

brew install pkg-config
brew install -s icu4c
brew link --force icu4c
brew install -s libpng libjpeg libtiff gtk-doc
brew install -s openjpeg ilmbase json-c libde265 nasm x265
brew link --force ilmbase
brew install -s xmlto py3cairo pygobject3
brew install -s gtk+3 gtk-mac-integration adwaita-icon-theme
brew install -s libarchive libyaml
brew link --force libarchive
brew install -s lcms2 glib-networking poppler fontconfig libmypaint libheif \
  aalib webp shared-mime-info iso-codes librsvg
brew install -s mypaint-brushes # Needs a formula, see https://github.com/macports/macports-ports/blob/master/graphics/mypaint-brushes/Portfile
# # left out webkit dependencies
brew install -s svn
brew install -s gexiv2 libwmf openexr libmng ghostscript
brew install -s appstream-glib
brew install -s babl gegl

# Things we need to make sure are not there because the compile breaks
brew uninstall vala || true
brew uninstall --ignore-dependencies gtk+ || true

# brew install SuiteSparse_AMD SuiteSparse_CAMD SuiteSparse_CCOLAMD SuiteSparse_COLAMD SuiteSparse_CHOLMOD \
#   # SuiteSparse_UMFPACK metis
