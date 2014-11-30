
PKG_NAME="script.service.antiprism"
PKG_VERSION="1.2.20"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="BSD"
PKG_SITE="http://www.antiprism.ca"
PKG_WGET_AUTH="$GITHUB_AUTH"
PKG_URL="${ANTIPRISM_COMPONENTS_LOCATION}/$PKG_NAME/archive/$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="toolchain truecrypt plugin.program.truecrypt"
PKG_PRIORITY="optional"
PKG_SECTION=""
PKG_SHORTDESC="Set of anonymizing tools"
PKG_LONGDESC="AntiPrism is about browsing, emailing, chatting, talking, publishing safely and anonymously online."

PKG_IS_ADDON="yes"
PKG_AUTORECONF="no"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; unzip -o "$sourceDir/$FILE")
}

make_target() {
  echo "Making AntiPrism"
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin
  cp -R * $INSTALL/usr/share/xbmc/addons/$PKG_NAME

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -f
  rm -rf `find $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -name "*.py"`

  chmod a+x $PKG_DIR/scripts/*
  mkdir -p $INSTALL/usr/lib/openelec
  cp $PKG_DIR/scripts/* $INSTALL/usr/lib/openelec

}

post_install() {
  enable_service antiprism-shutdown.service
  enable_service antiprism-firewall.service
}

