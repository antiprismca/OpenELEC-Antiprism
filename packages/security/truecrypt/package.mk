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

PKG_NAME="truecrypt"
PKG_VERSION="7.1a-source"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.truecrypt.org"
PKG_FILE="TrueCrypt%207.1a%20Source.tar.gz"
PKG_URL="https://raw.githubusercontent.com/DrWhax/truecrypt-archive/master/$PKG_FILE"
PKG_DEPENDS_TARGET="toolchain LVM2 fuse"
PKG_BUILD_DEPENDS_TARGET="toolchain LVM2 fuse"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="TrueCrypt"
PKG_LONGDESC=""
PKG_MD5SUM="3ca3617ab193af91e25685015dc5e560"
truecrypt=$PKG_NAME-$PKG_VERSION

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

FUSE_VERSION="2.9.3"
VERBOSE="yes"

WGET_OPT="-O $SOURCES/$PKG_NAME/$PKG_FILE"

unpack() {
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$PKG_FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; mkdir "$PKG_NAME-$PKG_VERSION"; cd "$PKG_NAME-$PKG_VERSION"; tar -xzvf "$sourceDir/$PKG_FILE")
}

post_unpack() {
  cd $ROOT/$PKG_BUILD
  # disable threads
  cp $truecrypt/Makefile $truecrypt/Makefile.orig
  sed -e "s/WX_CONFIGURE_FLAGS\ :=/WX_CONFIGURE_FLAGS := --disable-threads --host ${TARGET_NAME}/g" -e "s/export LFLAGS\ :=/export LFLAGS := -ldl/g" $truecrypt/Makefile.orig > $truecrypt/Makefile
  [ -f $truecrypt/Crypto/pkcs11.h ] || cp $PKG_DIR/Crypto/pkcs11.h $truecrypt/Crypto/pkcs11.h
  [ -f $truecrypt/Crypto/pkcs11t.h ] || cp $PKG_DIR/Crypto/pkcs11t.h $truecrypt/Crypto/pkcs11t.h
  [ -f $truecrypt/Crypto/pkcs11f.h ] || cp $PKG_DIR/Crypto/pkcs11f.h $truecrypt/Crypto/pkcs11f.h
  if [ ! -d wxWidgets-2.8.12 ]
  then
    wget http://softlayer-dal.dl.sourceforge.net/project/wxwindows/2.8.12/wxWidgets-2.8.12.tar.bz2
    tar -xjvf wxWidgets-2.8.12.tar.bz2
  fi
  cd -
}

make_target() {
  cd $ROOT/$PKG_BUILD/$truecrypt
  make ARCH=${TARGET_NAME} NOGUI=1 WXSTATIC=1 WX_ROOT=$ROOT/$PKG_BUILD/wxWidgets-2.8.12 wxbuild
  make ARCH=${TARGET_NAME} NOTEST=1 NOGUI=1 WXSTATIC=1 PKCS11_INC=`echo "$ROOT/$PKG_BUILD" | sed -e "s/$PKG_NAME-$PKG_VERSION//g"`/fuse-$FUSE_VERSION/include WX_ROOT=$ROOT/$PKG_BUILD/wxWidgets-2.8.12
  $TARGET_STRIP Main/truecrypt
  cd -
}

makeinstall_target() {
  cd $ROOT/$PKG_BUILD
  mkdir -p $INSTALL/bin
  cp $truecrypt/Main/truecrypt $INSTALL/bin/
  cd -
}


