

PKG_NAME="plugin.program.i2p"
PKG_VERSION="1.0.12"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="BSD"
PKG_DEPENDS_TARGET="toolchain i2p.i2p-bote"
PKG_PRIORITY="optional"
PKG_SECTION="addons"
PKG_SHORTDESC="I2P XBMC Frontend"
PKG_LONGDESC="I2P XBMC Frontend"
PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="plugin.program"
PKG_AUTORECONF="no"
PKG_MAINTAINER="AntiPrism.ca (antiprism@antiprism.ca)"

make_target() {
  :  
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  cp -R $PKG_DIR/source/* $INSTALL/usr/share/xbmc/addons/$PKG_NAME

  #python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -f
  #rm -rf `find $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -name "*.py"`

  chmod a+x $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin/addressbook.sh

}

post_makeinstall_target() {
  if (test -d $INSTALL/usr/share/xbmc) && (test ! -e $INSTALL/usr/share/kodi); then
    mv $INSTALL/usr/share/xbmc $INSTALL/usr/share/kodi
    ln -s kodi $INSTALL/usr/share/xbmc
  fi
}

