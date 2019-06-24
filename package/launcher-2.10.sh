#!/bin/sh

# on some OSX installations open file limit is 256 and GIMP needs more
ulimit -n 7000

## uncomment to debug loader issues
## see `man dyld` for the reference
# export DYLD_PRINT_TO_FILE=1
# export DYLD_PRINT_OPTS=1
# export DYLD_PRINT_ENV=1
# export DYLD_PRINT_LIBRARIES=1
# export DYLD_PRINT_APIS=1
# export DYLD_PRINT_BINDINGS=1
# export DYLD_PRINT_INITIALIZERS=1
# export DYLD_PRINT_REBASINGS=1
# export DYLD_PRINT_SEGMENTS=1
# export DYLD_PRINT_STATISTICS=1
# export DYLD_PRINT_DOFS=1
# export DYLD_PRINT_RPATHS=1

BASEDIR=$(cd `dirname $0` && pwd)

cd "$BASEDIR"

export PATH="${BASEDIR}:$PATH"
export GTK_PATH="${BASEDIR}/../Resources/lib/gtk-2.0/2.10.0"
export GTK_IM_MODULE_FILE="${BASEDIR}/../Resources/etc/gtk-2.0/gtk.immodules"
export GEGL_PATH="${BASEDIR}/../Resources/lib/gegl-0.4"
export BABL_PATH="${BASEDIR}/../Resources/lib/babl-0.1"
export GDK_PIXBUF_MODULE_FILE="${BASEDIR}/../Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export FONTCONFIG_PATH="${BASEDIR}/../Resources/etc/fonts"
export PYTHONHOME="${BASEDIR}/../Resources"
export PYTHONPATH="${BASEDIR}/../Resources/lib/python2.7:${BASEDIR}/../Resources/lib/gimp/2.0/python"
export GIO_MODULE_DIR="${BASEDIR}/../Resources/lib/gio/modules"
export WMF_FONTDIR="${BASEDIR}/../Resources/share/libwmf/fonts"
export XDG_CACHE_HOME="${HOME}/Library/Application Support/GIMP/2.10/cache"

# Strip out the argument added by the OS.
if /bin/expr "x$1" : '^x-psn_' > /dev/null; then
 shift 1
fi

exec ./gimp-bin "$@"


