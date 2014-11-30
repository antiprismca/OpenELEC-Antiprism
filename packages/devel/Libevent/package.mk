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

PKG_NAME="Libevent"
PKG_VERSION="release-2.0.21-stable"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://libevent.org/"
PKG_URL="https://github.com/nmathewson/$PKG_NAME/archive/$PKG_VERSION.zip"
PKG_DEPENDS=""
PKG_BUILD_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="devel"
PKG_SHORTDESC="libevent – an event notification library"
PKG_LONGDESC="The libevent API provides a mechanism to execute a callback function when a specific event occurs on a file descriptor or after a timeout has been reached. Furthermore, libevent also support callbacks due to signals or regular timeouts."

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; unzip -o "$sourceDir/$FILE")
}

post_makeinstall_target() {
  cp -R $INSTALL/usr/include/* $SYSROOT_PREFIX/usr/include
  rm -rf $INSTALL/usr/bin
  rm -rf $INSTALL/usr/share
}

