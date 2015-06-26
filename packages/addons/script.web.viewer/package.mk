
PKG_NAME="script.web.viewer"
PKG_VERSION="0.9.15"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/ruuk/script.web.viewer/"
PKG_URL="http://mirrors.kodi.tv/addons/gotham/script.web.viewer/$PKG_NAME-$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="toolchain script.module.mechanize"
PKG_PRIORITY="optional"
PKG_SECTION=""
PKG_SHORTDESC="WebViewer addon for Kodi (XBMC)"
PKG_LONGDESC="WebViewer addon for Kodi (XBMC) - browse web pages from Kodi with a sad text interface"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

post_unpack() {
  [ -d "$ROOT/$PKG_BUILD" ] || mv `echo "$ROOT/$PKG_BUILD" | sed -e "s/$PKG_NAME-$PKG_VERSION/$PKG_NAME/g"` $ROOT/$PKG_BUILD
}

make_target() {
 : # do nothing
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/kodi/addons
  cp -r $ROOT/$PKG_BUILD/* $INSTALL/usr/share/kodi/addons

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/kodi/addons/$PKG_NAME/lib/webviewer/ -f
#  rm -rf `find $INSTALL/usr/share/kodi/addons/$PKG_NAME/lib/webviewer/ -name "*.py"`
}

