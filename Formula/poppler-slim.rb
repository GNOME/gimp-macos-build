class PopplerSlim < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-22.06.0.tar.xz"
  sha256 "a0f9aaa3918bad781039fc307a635652a14d1b391cd559b66edec4bedba3c5d7"
  license "GPL-2.0-only"
  head "https://gitlab.freedesktop.org/poppler/poppler.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?poppler[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "little-cms2"
  depends_on "nspr"
  depends_on "openjpeg"

  uses_from_macos "gperf" => :build
  uses_from_macos "curl", since: :catalina # 7.55.0 required by poppler
  uses_from_macos "zlib"

  on_linux do
    depends_on "gcc"
  end

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    because: "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  fails_with gcc: "5"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.11.tar.gz"
    sha256 "2cec05cd1bb03af98a8b06a1e22f6e6e1a65b1e2f3816cb3069bb0874825f08c"
  end

  # Missing std::optional function
  # https://stackoverflow.com/questions/44217316/how-do-i-use-stdoptional-in-c
  patch :DATA if MacOS.version < :high_sierra

  def install
    ENV.cxx11

    # removes /usr/include from CFLAGS (not clear why)
    ENV["PKG_CONFIG_SYSTEM_INCLUDE_PATH"] = "/usr/include" if MacOS.version < :mojave

    args = std_cmake_args + %w[
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_BOOST=OFF
      -DENABLE_CMS=lcms2
      -DENABLE_QT5=OFF
      -DENABLE_QT6=OFF
      -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
      -DWITH_GObjectIntrospection=ON
      -DWITH_NSS3:BOOL=OFF
    ]

    system "cmake", ".", *args, "--trace-expand"
    system "make", "install"
    system "make", "clean"
    system "cmake", ".", "-DBUILD_SHARED_LIBS=OFF", *args
    system "make"
    lib.install "libpoppler.a"
    lib.install "cpp/libpoppler-cpp.a"
    lib.install "glib/libpoppler-glib.a"
    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end

    if OS.mac?
      libpoppler = (lib/"libpoppler.dylib").readlink
      [
        "#{lib}/libpoppler-cpp.dylib",
        "#{lib}/libpoppler-glib.dylib",
        *Dir["#{bin}/*"],
      ].each do |f|
          macho = MachO.open(f)
          macho.change_dylib("@rpath/#{libpoppler}", "#{opt_lib}/#{libpoppler}")
          macho.write!
      end
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end

__END__
diff --git a/poppler/SplashOutputDev.cc b/poppler/SplashOutputDev.cc
index 695f867..cdb774b 100644
--- a/poppler/SplashOutputDev.cc
+++ b/poppler/SplashOutputDev.cc
@@ -1912,7 +1912,7 @@ reload:
         if (!fileName.empty()) {
             fontsrc->setFile(fileName);
         } else {
-            fontsrc->setBuf(std::move(tmpBuf.value()));
+            fontsrc->setBuf(std::move(*tmpBuf));
         }
 
         // load the font file
diff --git a/poppler/CairoFontEngine.cc b/poppler/CairoFontEngine.cc
index f73b420..a2f8896 100644
--- a/poppler/CairoFontEngine.cc
+++ b/poppler/CairoFontEngine.cc
@@ -233,7 +233,7 @@ CairoFreeTypeFont *CairoFreeTypeFont::create(const std::shared_ptr<GfxFont> &gfx
         if (!fd || fd->empty()) {
             goto err2;
         }
-        font_data = std::move(fd.value());
+        font_data = std::move(*fd);
 
         // external font
     } else { // gfxFontLocExternal
