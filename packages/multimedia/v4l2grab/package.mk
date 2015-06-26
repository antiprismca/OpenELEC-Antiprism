
PKG_NAME="v4l2grab"
PKG_VERSION="0.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_DEPENDS_TARGET="toolchain libjpeg-turbo"
PKG_PRIORITY="optional"
PKG_SECTION="multimedia"
PKG_SHORTDESC="v4l2grab"
PKG_LONGDESC="based on V4L2 Specification, Appendix B: Video Capture Example"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"


make_target() {
  cp -f $PKG_DIR/Makefile .
  cp -f $PKG_DIR/v4l2grab.c .
  make CFLAGS="-DIO_READ -DIO_MMAP -DIO_USERPTR"
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp -f v4l2grab $INSTALL/usr/bin 
}

post_makeinstall_target() {
  $STRIP $INSTALL/usr/bin/v4l2grab
}

