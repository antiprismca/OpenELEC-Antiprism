

PKG_NAME="script.service.antiprism"
PKG_VERSION="1.2.24"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="BSD"
PKG_SITE="http://www.antiprism.ca"
if [ "$TARGET_ARCH" = "arm" ]; then
  PKG_DEPENDS_TARGET="toolchain hiawatha"
else
  PKG_DEPENDS_TARGET="toolchain truecrypt plugin.program.truecrypt hiawatha"
fi
PKG_PRIORITY="optional"
PKG_SECTION="addons"
PKG_SHORTDESC="Set of anonymizing tools"
PKG_LONGDESC="AntiPrism is about browsing, emailing, chatting, talking, publishing safely and anonymously online."
PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="script.service"
PKG_AUTORECONF="no"
PKG_MAINTAINER="AntiPrism.ca (antiprism@antiprism.ca)"

make_target() {
  mkdir -p $ROOT/$PKG_BUILD
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin
  cp -R $PKG_DIR/source/* $INSTALL/usr/share/xbmc/addons/$PKG_NAME

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -f
  rm -rf `find $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -name "*.py"`

  chmod a+x $PKG_DIR/scripts/*
  mkdir -p $INSTALL/usr/lib/openelec
  cp $PKG_DIR/scripts/* $INSTALL/usr/lib/openelec
  if [ "$TARGET_ARCH" = "arm" ]; then
    mv -f $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/settings.xml.arm $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/settings.xml
  else
    rm -f $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/settings.xml.arm
  fi
}

post_makeinstall_target() {
  if (test -d $INSTALL/usr/share/xbmc) && (test ! -e $INSTALL/usr/share/kodi); then
    mv $INSTALL/usr/share/xbmc $INSTALL/usr/share/kodi
    ln -s kodi $INSTALL/usr/share/xbmc
  fi
}

post_install() {
  enable_service antiprism-shutdown.service
  enable_service antiprism-firewall.service
}



