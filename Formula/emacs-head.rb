class EmacsHead < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://ftp.gnu.org/gnu/emacs/emacs-26.2.tar.xz"
  mirror "https://ftpmirror.gnu.org/emacs/emacs-26.2.tar.xz"
  sha256 "151ce69dbe5b809d4492ffae4a4b153b2778459de6deb26f35691e1281a9c58e"
  revision 1

  bottle do
    rebuild 4
    root_url "https://dl.bintray.com/daviderestivo/homebrew-emacs-head"
    sha256 "338d469ad09e7489c1c5bfb55d767bbb4b637c349261b1bf1e8aa1e3fa00c741" => :sierra
    sha256 "9d3828efa14e0f3732701997f9a63c8ab9f239872890a1b746b01f7855e2ebd3" => :high_sierra
    sha256 "5eb9ec8a4e4b5dbe3cbbfd435333c8b8e09f64e6f0be8e34c692512d636f13cd" => :mojave
  end

  head do
    url "https://github.com/emacs-mirror/emacs.git"

    depends_on "autoconf" => :build
    depends_on "gnu-sed" => :build
    depends_on "texinfo" => :build
  end

  option "with-cocoa",
         "Build a Cocoa version of GNU Emacs"
  option "with-ctags",
         "Don't remove the ctags executable that GNU Emacs provides"
  option "with-dbus",
         "Build with dbus support"
  option "without-gnutls",
         "Disable gnutls support"
  option "with-imagemagick@6",
         "Build with imagemagick@6 support"
  option "with-imagemagick@7",
         "Build with imagemagick@7 support (only HEAD)"
  option "with-jansson",
         "Enable jansson support (only HEAD)"
  option "without-librsvg",
         "Disable librsvg support"
  option "with-mailutils",
         "Build with mailutils support"
  option "with-multicolor-fonts",
         "Enable multicolor fonts on macOS"
  option "without-modules",
         "Disable dynamic modules support"
  option "with-no-frame-refocus",
         "Disables frame re-focus (i.e. closing one frame does not refocus another one)"
  option "without-libxml2",
         "Disable libxml2 support"

  depends_on "pkg-config" => :build
  depends_on "gnutls"
  depends_on "librsvg"
  depends_on "libxml2"
  depends_on "dbus" => :optional
  # Emacs 26.x does not support ImageMagick 7:
  # Reported on 2017-03-04: https://debbugs.gnu.org/cgi/bugreport.cgi?bug=25967
  depends_on "imagemagick@6"
  # Emacs 27.x (current HEAD) does support ImageMagick 7
  depends_on "imagemagick@7" => :optional
  depends_on "jansson" => :optional
  depends_on "mailutils" => :optional

  # When closing a frame, Emacs automatically focuses another frame.
  # This re-focus has an additional side-effect: when closing a frame
  # from one desktop/space, one gets automatically moved to another
  # desktop/space where the refocused frame lives. The below patch
  # disable this behaviour.
  # Reference: https://github.com/d12frosted/homebrew-emacs-plus/issues/119
  if build.with? "no-frame-refocus"
    patch do
      url "https://raw.githubusercontent.com/daviderestivo/homebrew-emacs-head/master/patches/0001-No-frame-refocus-cocoa.patch"
      sha256 "f004e6e65b969bbe83f5d6d53e4ba0e020631959da9ef9682479f7eeb09becd1"
    end
  end

  # Multicolor font support for macoOS has been re-enable on GNU Emacs
  # master branch:
  # https://github.com/emacs-mirror/emacs/commit/28220664714c50996d8318788289e1c69d69b8ab
  if build.head? && build.with?("multicolor-fonts")
    odie "Multicolor font support has been re-enabled on GNU Emacs HEAD. Please remove --with-multicolor-fonts."
  end

  # The multicolor-fonts patch is only needed on GNU Emacs 26.2
  if !build.head? && build.with?("multicolor-fonts")
    patch do
      url "https://raw.githubusercontent.com/daviderestivo/homebrew-emacs-head/master/patches/0002-Patch-multicolor-font.diff"
      sha256 "5af2587e986db70999d1a791fca58df027ccbabd75f45e4a2af1602c75511a8c"
    end
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
      --without-x
    ]

    if build.with? "dbus"
      args << "--with-dbus"
    else
      args << "--without-dbus"
    end

    if build.with?("imagemagick@6") && build.with?("imagemagick@7")
      odie "--with-imagemagick@6 and --with-imagemagick@7 are mutually exclusive"
    end

    # Note that if ./configure is passed --with-imagemagick but can't find the
    # library it does not fail but imagemagick support will not be available.
    # See: https://debbugs.gnu.org/cgi/bugreport.cgi?bug=24455
    if build.with?("imagemagick@6") || build.with?("imagemagick@7")
      args << "--with-imagemagick"
    else
      args << "--without-imagemagick"
    end

    if build.with? "imagemagick@6"
      imagemagick_lib_path = Formula["imagemagick@6"].opt_lib/"pkgconfig"
      ohai "ImageMagick PKG_CONFIG_PATH: ", imagemagick_lib_path
      ENV.prepend_path "PKG_CONFIG_PATH", imagemagick_lib_path
    end

    # Emacs 27.x (current HEAD) supports imagemagick7 but not Emacs 26.x
    if build.with? "imagemagick@7"
      imagemagick_lib_path = Formula["imagemagick@7"].opt_lib/"pkgconfig"
      unless build.head?
        odie "--with-imagemagick@7 is supported only on --HEAD"
      end
      ohai "ImageMagick PKG_CONFIG_PATH: ", imagemagick_lib_path
      ENV.prepend_path "PKG_CONFIG_PATH", imagemagick_lib_path
    end

    if build.with? "jansson"
      unless build.head?
        odie "--with-jansson is supported only on --HEAD"
      end
      args << "--with-json"
    end

    args << "--with-modules" unless build.without? "modules"
    args << "--without-pop"  if     build.with?    "mailutils"
    args << "--with-gnutls"  unless build.without? "gnutls"
    args << "--with-rsvg"    unless build.without? "librsvg"
    args << "--with-xml2"    unless build.without? "libxml2"

    if build.head?
      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
      system "./autogen.sh"
    end

    if build.with? "cocoa"
      args << "--with-ns" << "--disable-ns-self-contained"

      system "./configure", *args
      system "make"
      system "make", "install"

      prefix.install "nextstep/Emacs.app"

      # Replace the symlink with one that avoids starting Cocoa.
      (bin/"emacs").unlink # Kill the existing symlink
      (bin/"emacs").write <<~EOS
        #!/bin/bash
        exec #{prefix}/Emacs.app/Contents/MacOS/Emacs "$@"
      EOS
    else
      args << "--without-ns"

      system "./configure", *args
      system "make"
      system "make", "install"
    end

    # Follow MacPorts and don't install ctags from Emacs. This allows Vim
    # and Emacs and ctags to play together without violence.
    if build.without? "ctags"
      (bin/"ctags").unlink
      (man1/"ctags.1.gz").unlink
    end
  end

  def caveats
    <<~EOS
      Emacs.app was installed to:
        #{prefix}
      To link the application:
        ln -s #{prefix}/Emacs.app /Applications
    EOS
  end

  plist_options :manual => "emacs"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/emacs</string>
        <string>--fg-daemon</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
    </dict>
    </plist>
  EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
