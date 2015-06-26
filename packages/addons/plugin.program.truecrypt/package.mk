################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="plugin.program.truecrypt"
PKG_VERSION="3.1.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://dl.dropboxusercontent.com/u/8224157/public/truecrypt/index.html"
PKG_URL="http://dl.dropboxusercontent.com/u/8224157/public/truecrypt/i386/plugin.program.truecrypt-3.1.1.zip"
PKG_DEPENDS_TARGET="truecrypt"
PKG_PRIORITY="optional"
PKG_SECTION=""
PKG_SHORTDESC="Truecrypt addon for OpenELEC"
PKG_LONGDESC="Truecrypt addon for OpenELEC"

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
  (cd "$ROOT/$PKG_BUILD"
      for f in $(find . -name '*.py' -type f); do
          cp "$f" "$f.orig~"
          tr -d '\r' <"$f.orig~" >"$f"
          rm -f "$f.orig~"
      done)
}

make_target() {
  :  
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin
  mkdir -p $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources

  sed -e "s/echo\ \"Adding\ addon\ bin\ dir\ to\ PATH\.\"\ >\&2/:/g" -e "s/export\ PATH\=\$PATH\:\$ADDON\_DIR\/bin/:/g" -e "s/truecrypt\ \-\-non\-interactive\ \-\-protect\-hidden\=no\ \-m\=nokernelcrypto\ \-k\ \"\$keyfiles\"\ \-p\ \"\$pass\"\ /echo \"\$pass\" | truecrypt --protect-hidden=no -m=nokernelcrypto -k \"\$keyfiles\" /g" -e "s/truecrypt\ \-\-non\-interactive\ \-\-protect\-hidden\=no\ \-m\=nokernelcrypto\ \-\-filesystem\=ntfs\-3g\ \-k\ \"\$keyfiles\"\ \-p\ \"\$pass\"/echo \"\$pass\" | truecrypt --protect-hidden=no -m=nokernelcrypto --filesystem=ntfs-3g -k \"\$keyfiles\"/g" $ROOT/$PKG_BUILD/bin/truecrypt.sh > $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin/truecrypt.sh
  chmod a+x $INSTALL/usr/share/xbmc/addons/$PKG_NAME/bin/truecrypt.sh
  cp -R $ROOT/$PKG_BUILD/resources/* $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources
  sed -e "s/__settings__\.getSetting(\ \"truecrypt\"\ )/\"\/usr\/share\/xbmc\/addons\/plugin.program.truecrypt\/bin\/truecrypt.sh\"/g" $ROOT/$PKG_BUILD/resources/lib/tcitem.py > $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/tcitem.py
  grep -v TrueCrypt\.exe $ROOT/$PKG_BUILD/resources/settings.xml > $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/settings.xml
  cp $ROOT/$PKG_BUILD/addon.xml $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  cp $ROOT/$PKG_BUILD/changelog.txt $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  cp $ROOT/$PKG_BUILD/default.py $INSTALL/usr/share/xbmc/addons/$PKG_NAME
  cp $ROOT/$PKG_BUILD/icon.png $INSTALL/usr/share/xbmc/addons/$PKG_NAME

  python -Wi -t -B $ROOT/$TOOLCHAIN/lib/python2.7/compileall.py $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -f
  rm -rf `find $INSTALL/usr/share/xbmc/addons/$PKG_NAME/resources/lib/ -name "*.py"`

  chmod a+x $PKG_DIR/scripts/*
  mkdir -p $INSTALL/usr/lib/openelec
  cp $PKG_DIR/scripts/* $INSTALL/usr/lib/openelec
}

post_makeinstall_target() {
  if (test -d $INSTALL/usr/share/xbmc) && (test ! -e $INSTALL/usr/share/kodi); then
    mv $INSTALL/usr/share/xbmc $INSTALL/usr/share/kodi
    ln -s kodi $INSTALL/usr/share/xbmc
  fi
}

post_install() {
  enable_service loop-devices.service
}

