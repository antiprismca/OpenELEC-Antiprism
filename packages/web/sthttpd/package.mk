
PKG_NAME="sthttpd"
PKG_VERSION="2.27.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://opensource.dyc.edu/pub/sthttpd/"
PKG_URL="http://opensource.dyc.edu/pub/sthttpd/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="system"
PKG_SHORTDESC="sthttpd"
PKG_LONGDESC="This is a fork of Jef Poskanzer's popular thttpd server"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_target() {
  cd $ROOT/$PKG_BUILD
  ./configure --prefix=/usr --srcdir=$ROOT/$PKG_BUILD/ --host=$TARGET_NAME
  cd src
  make
}

