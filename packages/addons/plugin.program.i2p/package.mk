
PKG_NAME="plugin.program.i2p"
PKG_VERSION="1.0.12"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="BSD"
PKG_SITE="http://www.antiprism.ca/"
PKG_URL="http://www.antiprism.ca/releases/$PKG_NAME-$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="toolchain i2p.i2p-bote"
PKG_PRIORITY="optional"
PKG_SECTION="addons"
PKG_SHORTDESC="I2P XBMC Frontend"
PKG_LONGDESC="I2P XBMC Frontend"

PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="plugin.program"

PKG_AUTORECONF="no"

PKG_MAINTAINER="antiprism.ca"

post_unpack() {
  [ -d "$ROOT/$PKG_BUILD" ] || mv `echo "$ROOT/$PKG_BUILD" | sed -e "s/$PKG_NAME-$PKG_VERSION/$PKG_NAME/g"` $ROOT/$PKG_BUILD
  if [ -d $ROOT/$PKG_BUILD/$PKG_NAME ]
  then
    cp -R $ROOT/$PKG_BUILD/$PKG_NAME/* $ROOT/$PKG_BUILD
    rm -rf $ROOT/$PKG_BUILD/$PKG_NAME
  fi
}

make_target() {
  :  
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  cp -R $ROOT/$PKG_BUILD/* $INSTALL/usr/share/xbmc/addons/$PKG_NAME

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -f
  rm -rf `find $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -name "*.py"`

  chmod a+x $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin/addressbook.sh

}


