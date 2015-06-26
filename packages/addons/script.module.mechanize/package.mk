
PKG_NAME="script.module.mechanize"
PKG_VERSION="0.2.6"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/jjlee/mechanize"
PKG_URL="http://ftp.yzu.edu.tw/kodi/addons/gotham/script.module.mechanize/$PKG_NAME-$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION=""
PKG_SHORTDESC="Stateful programmatic web browsing in Python"
PKG_LONGDESC="Stateful programmatic web browsing in Python, after Andy Lester’s Perl module WWW::Mechanize"

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

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/kodi/addons/$PKG_NAME/lib/mechanize/ -f
}

