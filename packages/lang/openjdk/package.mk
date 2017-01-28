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
PKG_VERSION="jdk8u66-b17"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.oracle.com"
PKG_URL="\
    http://hg.openjdk.java.net/jdk8u/jdk8u/archive/a482cd45f31d.zip
    http://hg.openjdk.java.net/jdk8u/jdk8u/corba/archive/efb736c1edb9.zip \
    http://hg.openjdk.java.net/jdk8u/jdk8u/hotspot/archive/9ae2a5adabba.zip \
    http://hg.openjdk.java.net/jdk8u/jdk8u/jaxp/archive/4ae0c2d6dd24.zip \
    http://hg.openjdk.java.net/jdk8u/jdk8u/jaxws/archive/f3e9f0fcf556.zip \
    http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/archive/fd2fe69089ac.zip \
    http://hg.openjdk.java.net/jdk8u/jdk8u/langtools/archive/ee701de614ad.zip \
    http://hg.openjdk.java.net/jdk8u/jdk8u/nashorn/archive/39bfb9eb75dc.zip"

PKG_DEPENDS_TARGET="cups libXtst llvm"
PKG_BUILD_DEPENDS_TARGET="toolchain cups libXtst"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="Open JDK"
PKG_LONGDESC="Open JDK"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

unpack() {
  for url in $PKG_URL; do
    local folder=$(echo $url |\
        sed 's%/jdk8u/archive/%/jdk8u/jdk8u/archive/%;s%^http://hg.openjdk.java.net/jdk8u/jdk8u/%%;s%/archive/.*$%%')
    local hash=$(basename "$url" .zip)
    local filename="$SOURCES/$PKG_NAME/${hash}.zip"
    if test ! -f "$filename"; then echo "File $filename not found"; exit 2; fi
    local target_dir="$BUILD/$PKG_NAME-$PKG_VERSION"
    mkdir -p "$target_dir"
    target_name="$BUILD/$PKG_NAME-$PKG_VERSION/${folder}-${hash}"
    unzip "$filename" -d "$target_dir"
    if test $? -ne 0; then echo "ERROR $?"; exit 2; fi
    if test ! -d "$target_dir/${folder}-${hash}"; then echo "Directory $target_dir/${folder}-${hash} not found"; exit 2; fi
    mv "$target_dir/${folder}-${hash}" "$target_dir/$folder"
    if test $? -ne 0; then echo "ERROR $?"; exit 2; fi
  done
  (cd $target_dir
    mv corba hotspot jaxp jaxws jdk langtools nashorn jdk8u
    if test ! -f jdk8u/configure; then echo "File jdk8u/configure not found"; exit 2; fi
    chmod +x jdk8u/configure
    mv jdk8u/* .)
    if test $? -ne 0; then echo "ERROR $?"; exit 2; fi
}

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


