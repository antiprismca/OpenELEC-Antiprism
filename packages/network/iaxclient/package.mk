
PKG_NAME="iaxclient"
PKG_VERSION="2.1beta3"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://sourceforge.net/projects/iaxclient/"
PKG_URL="http://softlayer-dal.dl.sourceforge.net/project/$PKG_NAME/$PKG_NAME/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain speex alsa-lib portaudio ffmpeg"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="iaxclient"
PKG_LONGDESC="A lightweight cross platform IP telephony client using the IAX protocol, designed for use with the asterisk open source PBX."
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_target() {
  cd $ROOT/$PKG_BUILD
  ./autogen.sh
  ./configure --prefix=/usr --host=$TARGET_NAME --enable-shared=no --enable-static=yes --enable-clients=testcall --enable-video=no --without-ogg --without-theora --without-vidcap --with-ffmpeg --includedir=$SYSROOT_PREFIX/usr/include --oldincludedir=$SYSROOT_PREFIX/usr/include --srcdir=$ROOT/$PKG_BUILD/
  make
  cd -
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/simpleclient/testcall/testcall $INSTALL/usr/bin
}

post_makeinstall_target() {
  ${TARGET_STRIP} "$INSTALL/usr/bin/testcall"
}

