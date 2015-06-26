
PKG_NAME="gpm"
PKG_VERSION="1.99.7"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE=" http://www.nico.schottelius.org/"
PKG_URL=" http://www.nico.schottelius.org/software/gpm/archives/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="system"
PKG_SHORTDESC="gpm"
PKG_LONGDESC="gpm - general purpose mouse "

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

export TARGET_CFLAGS="$TARGET_CFLAGS -Wno-extra -Wno-error=unused-but-set-parameter -Wno-error=unused-but-set-variable"

make_target() {
  cd $ROOT/$PKG_BUILD
  ./configure --prefix=/usr --srcdir=$ROOT/$PKG_BUILD/ --host=$TARGET_NAME
  cd src
  make
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  mkdir -p $INSTALL/usr/lib

  cp $ROOT/$PKG_BUILD/src/prog/gpm-root $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/prog/get-versions $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/prog/display-coords $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/prog/display-buttons $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/prog/disable-paste $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/prog/mouse-test $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/prog/mev $INSTALL/usr/bin

  $STRIP $INSTALL/usr/bin/gpm-root
  $STRIP $INSTALL/usr/bin/get-versions
  $STRIP $INSTALL/usr/bin/display-coords
  $STRIP $INSTALL/usr/bin/display-buttons
  $STRIP $INSTALL/usr/bin/disable-paste
  $STRIP $INSTALL/usr/bin/mouse-test
  $STRIP $INSTALL/usr/bin/mev

  cp $ROOT/$PKG_BUILD/src/lib/libgpm.so.2.1.0 $INSTALL/usr/lib
  $STRIP $INSTALL/usr/lib/libgpm.so.2.1.0
  cd $INSTALL/usr/lib
  ln -s libgpm.so.2.1.0 libgpm.so.2
}


