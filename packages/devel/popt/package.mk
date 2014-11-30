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

PKG_NAME="popt"
PKG_VERSION="1.7"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://launchpad.net/"
PKG_URL="https://launchpad.net/ubuntu/+archive/primary/+files/popt_1.7.orig.tar.gz"
PKG_DEPENDS=""
PKG_BUILD_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="devel"
PKG_SHORTDESC="popt"
PKG_LONGDESC="This is the popt command line option parsing library."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

make_target() {
  cd $ROOT/$PKG_BUILD
  ./configure --prefix=/usr --host=$ARCH-unknown-linux-gnu --disable-static --disable-nls
  make libpopt.la
  cd -
}

makeinstall_target() {
  cp -f $ROOT/$PKG_BUILD/popt.h $SYSROOT_PREFIX/usr/include
  mkdir -p $INSTALL/usr
  mkdir -p $INSTALL/usr/lib
  mkdir -p $SYSROOT_PREFIX/usr/lib
  cp -f $ROOT/$PKG_BUILD/.libs/libpopt.so.0.0.0 $INSTALL/usr/lib
  ln -s -f libpopt.so.0.0.0 $INSTALL/usr/lib/libpopt.so.0
  ln -s -f libpopt.so.0.0.0 $INSTALL/usr/lib/libpopt.so
  cp -f $ROOT/$PKG_BUILD/.libs/libpopt.so.0.0.0 $SYSROOT_PREFIX/usr/lib
  ln -s -f libpopt.so.0.0.0 $SYSROOT_PREFIX/usr/lib/libpopt.so.0
  ln -s -f libpopt.so.0.0.0 $SYSROOT_PREFIX/usr/lib/libpopt.so
}

