
PKG_NAME="portaudio"
PKG_VERSION="20140130"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://www.portaudio.com/"
PKG_URL="http://www.portaudio.com/archives/pa_stable_v19_20140130.tgz"
PKG_DEPENDS_TARGET="toolchain alsa-lib"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="portaudio"
PKG_LONGDESC="PortAudio is a free, cross-platform, open-source, audio I/O library."
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; tar -xzvf "$sourceDir/$FILE")
}

post_unpack() {
  [ -d "$ROOT/$PKG_BUILD" ] || mv `echo "$ROOT/$PKG_BUILD" | sed -e "s/$PKG_NAME-$PKG_VERSION/portaudio/g"` $ROOT/$PKG_BUILD
}

post_makeinstall_target() {
  ${TARGET_STRIP} "$INSTALL/usr/lib/libportaudio.so.2.0.0"
}

