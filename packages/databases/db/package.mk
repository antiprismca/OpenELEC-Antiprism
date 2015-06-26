
PKG_NAME="db"
PKG_VERSION="4.8.30.NC"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.oracle.com/"
PKG_URL="http://download.oracle.com/berkeley-db/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="Berkeley DB"
PKG_LONGDESC="Berkeley Database Libraries"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_target() {
  cd build_unix
  ../dist/configure --prefix=/usr --enable-cxx --host=${TARGET_NAME}
  make
}

post_makeinstall_target() {
  cp -f $INSTALL/usr/include/* $SYSROOT_PREFIX/usr/include
  cp -f -d $INSTALL/usr/lib/* $SYSROOT_PREFIX/usr/lib
  rm -rf $INSTALL/usr/docs
  rm -rf $INSTALL/usr/include
  rm -rf $INSTALL/usr/lib/*.a
  rm -rf $INSTALL/usr/lib/*.la
  chmod u+rw $INSTALL/usr/bin/*
  $STRIP $INSTALL/usr/bin/*
  chmod u+rw $INSTALL/usr/lib/*
  $STRIP $INSTALL/usr/lib/*
}

