################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2014 Stephan Raue (stephan@openelec.tv)
#
#  OpenELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  OpenELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="gnupg"
PKG_VERSION="1.4.21"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="LGPL"
PKG_SITE="http://www.gnupg.org/"
PKG_URL="ftp://ftp.gnupg.org/gcrypt/gnupg/$PKG_NAME-$PKG_VERSION.tar.bz2"
PKG_DEPENDS_TARGET="toolchain zlib curl ncurses"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="GnuPG"
PKG_LONGDESC="GnuPG"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_TARGET="--disable-asm --with-libcurl"

configure_target() {
    $PKG_CONFIGURE_SCRIPT $TARGET_CONFIGURE_OPTS $PKG_CONFIGURE_OPTS_TARGET LIBS="-lncurses -ltinfo"
}

makeinstall_target() {
  mkdir -p $INSTALL/usr
  mkdir -p $INSTALL/usr/bin
  mkdir -p $INSTALL/usr/lib
  mkdir -p $INSTALL/usr/lib/gnupg
  cp g10/gpg $INSTALL/usr/bin
  cp tools/gpgsplit $INSTALL/usr/bin
  cp keyserver/gpgkeys_curl $INSTALL/usr/lib/gnupg 
  cp keyserver/gpgkeys_finger $INSTALL/usr/lib/gnupg 
  cp keyserver/gpgkeys_hkp $INSTALL/usr/lib/gnupg 
  cp keyserver/gpgkeys_mailto $INSTALL/usr/lib/gnupg
  ${TARGET_STRIP} $INSTALL/usr/bin/gpg
  ${TARGET_STRIP} $INSTALL/usr/bin/gpgsplit
  ${TARGET_STRIP} $INSTALL/usr/lib/gnupg/gpgkeys_curl
  ${TARGET_STRIP} $INSTALL/usr/lib/gnupg/gpgkeys_finger
  ${TARGET_STRIP} $INSTALL/usr/lib/gnupg/gpgkeys_hkp
}

