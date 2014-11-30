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

PKG_NAME="LVM2"
PKG_VERSION="2.02.105"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="ftp://sources.redhat.com/"
PKG_URL="ftp://sources.redhat.com/pub/lvm2/$PKG_NAME.$PKG_VERSION.tgz"
PKG_DEPENDS="toolchain"
PKG_BUILD_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="sysutils"
PKG_SHORTDESC="LVM2"
PKG_LONGDESC="LVM2 refers to the userspace toolset that provide logical volume management facilities on linux."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

# do not set "--enable-udev_sync"
PKG_CONFIGURE_OPTS_TARGET="\
    --enable-udev-systemd-background-jobs \
    --enable-udev_rules \
    --enable-udev-rule-exec-detection \
    --disable-testing \
"

post_unpack() {
  [ -d "$ROOT/$PKG_BUILD" ] || mv `echo "$ROOT/$PKG_BUILD" | sed -e "s/$PKG_NAME-$PKG_VERSION/$PKG_NAME\.$PKG_VERSION/g"` $ROOT/$PKG_BUILD
}

configure_target() {
  export ac_cv_func_malloc_0_nonnull=yes
  $PKG_CONFIGURE_SCRIPT $TARGET_CONFIGURE_OPTS $PKG_CONFIGURE_OPTS_TARGET
}

make_target() {
  make device-mapper
  $STRIP tools/dmsetup
  $STRIP libdm/ioctl/libdevmapper.so.1.02
}

makeinstall_target() {
  mkdir -p $INSTALL/sbin
  mkdir -p $INSTALL/lib
  cp tools/dmsetup $INSTALL/sbin/dmsetup
  cp libdm/ioctl/libdevmapper.so.1.02 $INSTALL/lib
  ln -s libdevmapper.so.1.02 $INSTALL/lib/libdevmapper.so
  cp libdm/ioctl/libdevmapper.so.1.02 $SYSROOT_PREFIX/usr/lib
  rm -f $SYSROOT_PREFIX/usr/lib/libdevmapper.so
  ln -s libdevmapper.so.1.02 $SYSROOT_PREFIX/usr/lib/libdevmapper.so
  cp include/libdevmapper.h $SYSROOT_PREFIX/usr/include
  mkdir -p $ROOT/$BUILD/image/system/usr/lib/udev/rules.d
  cp udev/*.rules $ROOT/$BUILD/image/system/usr/lib/udev/rules.d
}

