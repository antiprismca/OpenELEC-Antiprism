
PKG_NAME="onionphone"
PKG_VERSION="0.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://torfone.org/onionphone/"
PKG_DEPENDS_TARGET="toolchain tor alsa-lib"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="OnionPhone"
PKG_LONGDESC="OnionPhone is a VOIP tool for calling over Tor network."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

download() {
  local PACKAGE="$PKG_NAME-$PKG_VERSION"
  if (test ! -d "$ROOT/$SOURCES/$PKG_NAME") || (test ! -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz); then
    rm -rf $ROOT/$SOURCES/$PKG_NAME/tmp
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.md5
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.url
    mkdir -p $ROOT/$SOURCES/$PKG_NAME/tmp
    (cd $ROOT/$SOURCES/$PKG_NAME/tmp
    git clone https://github.com/gegel/onionphone
    mv onionphone $PACKAGE
    tar czf ../$PACKAGE.tar.gz $PACKAGE)
    echo $PKG_SITE >$ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.url
    (cd $ROOT/$SOURCES/$PKG_NAME; md5sum -t $PACKAGE.tar.gz >$PACKAGE.tar.gz.md5)
  fi
}

unpack() {
  local PACKAGE="$PKG_NAME-$PKG_VERSION"
  if (test ! -d "$ROOT/$PKG_BUILD") || (test ! -f "$ROOT/$PKG_BUILD/.openelec-unpack"); then
    (cd "$ROOT/$BUILD"
    rm -rf $PACKAGE
    tar xzf $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz
    cd $ROOT/$PKG_BUILD
    rm -rf ".openelec-unpack"
    for i in PKG_NAME PKG_VERSION PKG_REV PKG_SHORTDESC PKG_LONGDESC PKG_SITE PKG_URL PKG_SECTION; do
      eval val=\$$i
      echo "STAMP_$i=\"$val"\" >>".openelec-unpack"
    done)
  fi
}

pre_configure_target() {
  download
  unpack
}

configure_target() {
 : # do nothing
}

make_target() {
  cd $ROOT/$PKG_BUILD
  make 
  ${TARGET_STRIP} oph
  ${TARGET_STRIP} addkey 
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/oph $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/addkey $INSTALL/usr/bin
}

