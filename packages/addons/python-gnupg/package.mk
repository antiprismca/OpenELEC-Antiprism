

PKG_NAME="python-gnupg"
PKG_VERSION="0.3.7"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://pythonhosted.org/python-gnupg/"
PKG_URL="https://pypi.python.org/packages/source/p/$PKG_NAME/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain gnupg"
PKG_PRIORITY="optional"
PKG_SECTION="addons"
PKG_SHORTDESC="GnuPG Kodi Frontend"
PKG_LONGDESC="GnuPG Kodi Frontend. Visit http://www.antiprism.ca for more privacy tools."
PKG_MAINTAINER="AntiPrism.ca (antiprism@antiprism.ca)"
PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="plugin.program"
PKG_AUTORECONF="no"
PKG_ADDON_ID="plugin.program.gnupg"

make_target() {
  : # nothing to do here
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_ADDON_ID
  cp -R $PKG_DIR/source/* $INSTALL/usr/share/xbmc/addons/$PKG_ADDON_ID
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_ADDON_ID/resources/lib
  cp -f $ROOT/$PKG_BUILD/gnupg.py $INSTALL/usr/share/xbmc/addons/$PKG_ADDON_ID/resources/lib

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/xbmc/addons/$PKG_ADDON_ID/resources/lib/ -f
  rm -rf `find $INSTALL/usr/share/xbmc/addons/$PKG_ADDON_ID/resources/lib/ -name "*.py"`

}

post_makeinstall_target() {
  if (test -d $INSTALL/usr/share/xbmc) && (test ! -e $INSTALL/usr/share/kodi); then
    mv $INSTALL/usr/share/xbmc $INSTALL/usr/share/kodi
    ln -s kodi $INSTALL/usr/share/xbmc
  fi
}

