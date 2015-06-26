
PKG_NAME="tor-browser-linux32"
PKG_VERSION="4.0.4_en-US"
PKG_REV="1"
PKG_ARCH="i386"
PKG_LICENSE="GPL"
PKG_SITE="https://torproject.org/"
PKG_URL="https://dist.torproject.org/torbrowser/4.0.4/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain gtk+"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="Tor Browser Bundle"
PKG_LONGDESC="Everything you need to safely browse the Internet."
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

post_unpack() {
  [ -d "$ROOT/$PKG_BUILD" ] || mv `echo "$ROOT/$PKG_BUILD" | sed -e "s/$PKG_NAME-$PKG_VERSION/tor-browser_en-US/g"` $ROOT/$PKG_BUILD
}

make_target() {
  : # nope
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/tor-browser
  cp -r -f * $INSTALL/usr/share/tor-browser
}

