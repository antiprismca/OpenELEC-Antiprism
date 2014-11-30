
PKG_NAME="rxvt-unicode"
PKG_VERSION="9.20"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://software.schmorp.de/pkg/rxvt-unicode.html"
PKG_URL="http://dist.schmorp.de/rxvt-unicode/$PKG_NAME-$PKG_VERSION.tar.bz2"
PKG_DEPENDS="toolchain"
PKG_BUILD_DEPENDS_TARGET="toolchain libX11 ncurses"
PKG_PRIORITY="optional"
PKG_SECTION="x11/app"
PKG_SHORTDESC="The rxvt-unicode program is a terminal emulator for X Window System."
PKG_LONGDESC="rxvt-unicode is a fork of the well known terminal emulator rxvt"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_TARGET="--prefix=/usr --with-x --with-terminfo=/usr/share/terminfo/ --enable-everything --enable-256-color --enable-8bitctrls --disable-perl --x-includes=$SYSROOT_PREFIX/usr/include/X11/ --x-libraries=$SYSROOT_PREFIX/usr/X11/lib/"

post_makeinstall_target() {
  rm -rf $INSTALL/usr/share/
  rm -f $INSTALL/usr/bin/urxvtc
  rm -f $INSTALL/usr/bin/urxvtd
  strip $INSTALL/usr/bin/urxvt
}

