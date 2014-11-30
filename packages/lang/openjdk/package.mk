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

PKG_NAME="openjdk"
PKG_VERSION="8-src-b129-06_feb_2014"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.oracle.com"
PKG_URL="download.java.net/openjdk/jdk8/ri/$PKG_NAME-$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="cups libXtst"
PKG_BUILD_DEPENDS_TARGET="toolchain cups libXtst"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="Open JDK"
PKG_LONGDESC="Open JDK"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

configure_target() {
  test -n "$JAVA_HOME" || JAVA_HOME="`which javac | xargs -i{} readlink -f {}  | sed s%/bin/javac\$%% 2>/dev/null`"
  test -n "$JAVA_HOME" || (echo "JAVA_HOME must be set" >&2; exit 2)

  CC=`basename $TARGET_CC` \
  CXX=`basename $TARGET_CXX` \
  LD=`basename $TARGET_LD` \
  AS=`basename $TARGET_AS` \
  AR=`basename $TARGET_AR` \
  NM=`basename $TARGET_NM` \
  RANLIB=`basename $TARGET_RANLIB` \
  OBJCOPY=`basename $TARGET_OBJCOPY` \
  OBJDUMP=`basename $TARGET_OBJDUMP` \
  STRIP=`basename $TARGET_STRIP` \
  BUILD_CC=`which gcc` \
  BUILD_LD=`which gcc` \
  MAKEFLAGS="" \
    $PKG_CONFIGURE_SCRIPT \
              --openjdk-target=$TARGET_NAME \
              --with-sys-root=$SYSROOT_PREFIX \
              --prefix=/usr \
              --bindir=/usr/bin \
              --sbindir=/usr/sbin \
              --sysconfdir=/etc \
              --libexecdir=/usr/lib \
              --localstatedir=/var \
              --with-extra-cflags="$CFLAGS" \
              --with-extra-cxxflags="$CXXFLAGS" \
              --with-extra-ldflags="$LDFLAGS" \
              --disable-headful \
              --enable-openjdk-only \
              --enable-unlimited-crypto \
              --without-x \
              --with-zlib=system \
              --without-jtreg \
              --with-num-cores=1 \
              JAVA_HOME=$JAVA_HOME \
              POST_STRIP_CMD= \

}

make_target() {

  test -n "$JAVA_HOME" || JAVA_HOME="`which javac | xargs -i{} readlink -f {}  | sed s%/bin/javac\$%% 2>/dev/null`"
  test -n "$JAVA_HOME" || (echo "JAVA_HOME must be set" >&2; exit 2)

  CC=`basename $TARGET_CC` \
  CXX=`basename $TARGET_CXX` \
  LD=`basename $TARGET_LD` \
  AS=`basename $TARGET_AS` \
  AR=`basename $TARGET_AR` \
  NM=`basename $TARGET_NM` \
  RANLIB=`basename $TARGET_RANLIB` \
  OBJCOPY=`basename $TARGET_OBJCOPY` \
  OBJDUMP=`basename $TARGET_OBJDUMP` \
  STRIP=`basename $TARGET_STRIP` \
  MAKEFLAGS="-d" \
    $MAKE \
      JOBS=$CONCURRENCY_MAKE_LEVEL \
      LOG=debug \
      USE_PRECOMPILED_HEADER=0 \
      POST_STRIP_CMD= \
      images
}

unpack() {
  local FILE=`basename "$PKG_URL"`
  local NAME=`basename "$FILE" .zip`
  unzip -q "$SOURCES/$PKG_NAME/$FILE" -d "$BUILD"
  mv "$BUILD/$PKG_NAME" "$BUILD/$NAME"
  chmod +x "$BUILD/$NAME/configure"
}

makeinstall_target() {
  local IMAGE_DIR="`pwd`/images/j2re-image"
  mkdir -p "$INSTALL/usr/lib/jvm"
  (cd "$IMAGE_DIR"; tar cf - .) | (cd "$INSTALL/usr/lib/jvm"; tar xf -)
  find "$INSTALL/usr/lib/jvm" -name '*.diz' -type f -print0 | xargs --null rm
  mkdir -p "$INSTALL/usr/bin"
  (cd "$INSTALL/usr/bin"; ln -s ../lib/jvm/bin/* .)
}

post_makeinstall_target() {
  echo "Post install"
}


