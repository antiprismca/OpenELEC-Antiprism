
PKG_NAME="plugin.program.linksbrowser"
PKG_VERSION="1.0.2"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_DEPENDS_TARGET="toolchain links"
PKG_PRIORITY="optional"
PKG_SECTION="addons"
PKG_SHORTDESC="Links web browser plugin for OpenELEC"
PKG_LONGDESC="Links web browser plugin for OpenELEC"
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
}

post_makeinstall_target() {
  if (test -d $INSTALL/usr/share/xbmc) && (test ! -e $INSTALL/usr/share/kodi); then
    mv $INSTALL/usr/share/xbmc $INSTALL/usr/share/kodi
    ln -s kodi $INSTALL/usr/share/xbmc
  fi
}

