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

PKG_NAME="cups"
PKG_VERSION="1.7.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.cups.org"
PKG_URL="https://www.cups.org/software/$PKG_VERSION/$PKG_NAME-$PKG_VERSION-source.tar.bz2"
PKG_DEPENDS=""
PKG_BUILD_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="print"
PKG_SHORTDESC="CUPS open source printing system"
PKG_LONGDESC="CUPS is the standards-based, open source printing system developed by Apple Inc. for OS X® and other UNIX®-like operating systems. CUPS uses the Internet Printing Protocol (IPP) to support printing to local and network printers."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

TARGET_CONFIGURE_OPTS="\
  --disable-webif \
  --disable-launchd \
  --disable-dnssd \
  --disable-avahi \
  --disable-ssl \
  --disable-gssapi \
  --disable-libusb \
  --host=$ARCH-unknown-linux-gnu \
"

PKG_MAKE_OPTS_TARGET="libs"

PKG_MAKEINSTALL_OPTS_TARGET="install-libs install-headers"

pre_configure_target() {
  local DIRS_=$(find $ROOT/$PKG_BUILD -type d | sed s%^$ROOT/$PKG_BUILD%%\;/^$/d\;s%^/%%\;/^[.]/d)
  for d in $DIRS_ .; do
    mkdir -p $d
    for f in $ROOT/$PKG_BUILD/$d/*; do
      if test -f $f; then
        ln -s $f $d/`basename $f`
      fi
    done
  done
}

makeinstall_target() {
  $ROOT/$TOOLCHAIN/bin/make -j1 DESTDIR=$SYSROOT_PREFIX install-libs install-headers
  make DESTDIR=$INSTALL install-libs

}

