class Gimp3 < Formula
  desc "Gnu Image Processing Program"
  homepage "https://www.gimp.org/"
  url "https://gitlab.gnome.org/lukaso/gimp.git",
      # tag:      "5.5.1",
      # revision: "fa2835b2e60d60c924fc722a330524a378446a7d"
      branch: "master"
  version "2.99.11"
  license all_of: ["LGPL-3.0-or-later", "CC-BY-SA-3.0", "CC-BY-SA-4.0"]

  # livecheck do
  #   url "https://download.gimp.org/pub/gegl/0.4/"
  #   regex(/href=.*?gegl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  # end

  depends_on "glib" => :build
  depends_on "gobject-introspection" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build

  depends_on "aalib"
  depends_on "adwaita-icon-theme"
  depends_on "appstream-glib"
  depends_on "babl"
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "gegl-full"
  depends_on "gettext"
  depends_on "gexiv2"
  depends_on "ghostscript"
  depends_on "glib"
  depends_on "glib-networking"
  depends_on "gtk+3-fixed"
  depends_on "gtk-doc"
  depends_on "gtk-mac-integration-full"
  depends_on "harfbuzz"
  depends_on "icu4c"
  depends_on "ilmbase"
  depends_on "iso-codes"
  depends_on "jpeg"
  depends_on "json-c"
  depends_on "json-glib"
  depends_on "lcms2"
  depends_on "libarchive"
  depends_on "libde265"
  depends_on "libheif"
  depends_on "libmng"
  depends_on "libmypaint"
  depends_on "libpng"
  depends_on "librsvg"
  depends_on "libtiff"
  depends_on "libwmf"
  depends_on "libyaml"
  depends_on "mypaint-brushes"
  depends_on "nasm"
  depends_on "openexr"
  depends_on "openjpeg"
  depends_on "pango"
  depends_on "poppler"
  depends_on "py3cairo"
  depends_on "pygobject3"
  depends_on "python@3.9"
  depends_on "shared-mime-info"
  depends_on "webp"
  depends_on "x265"
  depends_on "xmlto"

  def install
    ### Temporary Fix ###
    # Temporary fix for a meson bug
    # Upstream appears to still be deciding on a permanent fix
    # See: https://gitlab.gnome.org/GNOME/gegl/-/issues/214
    # inreplace "subprojects/poly2tri-c/meson.build",
    #   "libpoly2tri_c = static_library('poly2tri-c',",
    #   "libpoly2tri_c = static_library('poly2tri-c', 'EMPTYFILE.c',"
    # touch "subprojects/poly2tri-c/EMPTYFILE.c"
    ### END Temporary Fix ###

    mkdir "build" do
      system "meson", "--prefix=#{prefix}",
                      "-Dvala-plugins=disabled",
                      "--libdir=#{lib}",
                      "-Dbuild-id=org.gimp.GIMP_official",
                      "-Drevision=0",
                      "--wrap-mode=nofallback"
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <gegl.h>
      gint main(gint argc, gchar **argv) {
        gegl_init(&argc, &argv);
        GeglNode *gegl = gegl_node_new ();
        gegl_exit();
        return 0;
      }
    EOS
    system ENV.cc,
           "-I#{Formula["babl"].opt_include}/babl-0.1",
           "-I#{Formula["glib"].opt_include}/glib-2.0",
           "-I#{Formula["glib"].opt_lib}/glib-2.0/include",
           "-L#{Formula["glib"].opt_lib}", "-lgobject-2.0", "-lglib-2.0",
           testpath/"test.c",
           "-I#{include}/gegl-0.4", "-L#{lib}", "-lgegl-0.4",
           "-o", testpath/"test"
    system "./test"
  end
end
