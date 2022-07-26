class Gimp3 < Formula
  desc "Gnu Image Processing Program"
  homepage "https://www.gimp.org/"
  url "https://gitlab.gnome.org/GNOME/gimp.git",
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
  depends_on "glib-utils"
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

  # May not fix anything, but keep it for now
  patch :DATA

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

__END__
diff --git a/app/main.c b/app/main.c
index 2a0c41e23c..cd1f360264 100644
--- a/app/main.c
+++ b/app/main.c
@@ -340,6 +340,7 @@ gimp_macos_setenv (const char * progname)
       gchar *res_dir;
       size_t path_len;
       struct stat sb;
+      gboolean need_pythonhome = TRUE;

       app_dir = g_path_get_dirname (resolved_path);
       tmp = g_strdup_printf ("%s/../Resources", app_dir);
@@ -371,6 +372,15 @@ gimp_macos_setenv (const char * progname)
             }
         }

+      /* Detect we were built in homebrew for MacOS */
+      tmp = g_strdup_printf ("%s/Frameworks/Python.framework", res_dir);
+      if (tmp && !stat (tmp, &sb) && S_ISDIR (sb.st_mode))
+        {
+          g_print ("GIMP was built with homebrew\n");
+          need_pythonhome = FALSE;
+        }
+      g_free (tmp);
+
       path_len = strlen (g_getenv ("PATH") ? g_getenv ("PATH") : "") + strlen (app_dir) + 2;
       path = g_try_malloc (path_len);
       if (path == NULL)
@@ -400,9 +410,12 @@ gimp_macos_setenv (const char * progname)
       tmp = g_strdup_printf ("%s/etc/fonts", res_dir);
       g_setenv ("FONTCONFIG_PATH", tmp, TRUE);
       g_free (tmp);
-      tmp = g_strdup_printf ("%s", res_dir);
-      g_setenv ("PYTHONHOME", tmp, TRUE);
-      g_free (tmp);
+      if (need_pythonhome)
+        {
+          tmp = g_strdup_printf ("%s", res_dir);
+          g_setenv ("PYTHONHOME", tmp, TRUE);
+          g_free (tmp);
+        }
       tmp = g_strdup_printf ("%s/lib/python3.9", res_dir);
       g_setenv ("PYTHONPATH", tmp, TRUE);
       g_free (tmp);
diff --git a/libgimpbase/gimpenv.c b/libgimpbase/gimpenv.c
index 00e16bf7b9..e7fe2cd220 100644
--- a/libgimpbase/gimpenv.c
+++ b/libgimpbase/gimpenv.c
@@ -441,6 +441,31 @@ gimp_installation_directory (void)
         g_free (tmp2);
         g_free (tmp3);
       }
+    else if (strstr(basepath, "Cellar"))
+      {
+        /*  we are running from a Python.framework bundle built in homebrew
+         *  during the build phase
+         */
+
+        gchar *fulldir = g_strdup (basepath);
+        gchar *lastdir = g_path_get_basename (fulldir);
+        gchar *tmp_fulldir;
+
+        while (strcmp (lastdir, "Cellar"))
+          {
+            tmp_fulldir = g_path_get_dirname (fulldir);
+
+            g_free (lastdir);
+            g_free (fulldir);
+
+            fulldir = tmp_fulldir;
+            lastdir = g_path_get_basename (fulldir);
+          }
+        toplevel = g_path_get_dirname (fulldir);
+
+        g_free (fulldir);
+        g_free (lastdir);
+      }
     else
       {
         /*  if none of the above match, we assume that we are really in a bundle  */
