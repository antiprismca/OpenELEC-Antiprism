
PKG_NAME="hiawatha"
PKG_VERSION="9.12"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://www.hiawatha-webserver.org/"
PKG_URL="https://www.hiawatha-webserver.org/files/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain libxslt cmake:host zlib"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="hiawatha"
PKG_LONGDESC="An advanced and secure webserver for Unix"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_target() {
  mkdir -p $ROOT/$PKG_BUILD/build
  cd $ROOT/$PKG_BUILD/build
  cmake -DCMAKE_TOOLCHAIN_FILE=$CMAKE_CONF -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_XSLT=off ..
  mkdir -p $INSTALL/etc/hiawatha
  cp $PKG_DIR/hiawatha.conf.tmpl $INSTALL/etc/hiawatha
  cp $PKG_DIR/cgi-wrapper.conf.tmpl $INSTALL/etc/hiawatha
  cp $ROOT/$PKG_BUILD/config/mimetype.conf $INSTALL/etc/hiawatha
}

post_makeinstall_target() {
  rm -rf $INSTALL/usr/etc
  rm -rf $INSTALL/usr/var
  rm -rf $INSTALL/usr/share
  ${TARGET_STRIP} "$INSTALL/usr/bin/ssi-cgi"
  ${TARGET_STRIP} "$INSTALL/usr/sbin/cgi-wrapper"
  ${TARGET_STRIP} "$INSTALL/usr/sbin/hiawatha"
  ${TARGET_STRIP} "$INSTALL/usr/sbin/wigwam"
  ${TARGET_STRIP} "$INSTALL/usr/lib/hiawatha/libmbedtls.so.1.3.10"
}

