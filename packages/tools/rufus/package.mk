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

PKG_NAME="rufus"
PKG_VERSION="d32e9dcb451b7d3a8d37241be73e5a3ae7837e8f"
PKG_LICENSE="GPL"
PKG_SITE="https://rufus.akeo.ie/"
PKG_URL="https://github.com/pbatard/${PKG_NAME}/archive/${PKG_VERSION}.zip"
PKG_DEPENDS_HOST="x86-mingw32-build:host"
PKG_PRIORITY="optional"
PKG_SECTION="tools"
PKG_SHORTDESC="rufus: Create bootable USB drives the easy way "
PKG_LONGDESC="Rufus is a utility that helps format and create bootable USB flash drives, such as USB keys/pendrives, memory sticks, etc."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; unzip -o "$sourceDir/$FILE")
}

post_patch() {
  cd `echo "$PKG_BUILD" | cut -f1 -d\ `
  chmod +x configure
  cd -
}

configure_host() {
  unset -v CC
  unset -v CXX
  unset -v CFLAGS
  unset -v CXXFLAGS
  unset -v LDFLAGS
  unset -v LDLIBS
  unset -v AR
  unset -v AS
  unset -v DLLTOOL
  unset -v LD
  unset -v NM
  unset -v OBJCOPY
  unset -v RANLIB
  unset -v STRIP
  unset -v TARGET_CPP
  
  export TARGET_NAME=i386-pc-mingw32
  export TARGET_PREFIX=$ROOT/$TOOLCHAIN/mingw32/bin/$TARGET_NAME-
  export CC=${TARGET_PREFIX}gcc
  export LD=${TARGET_PREFIX}ld
  export AS=${TARGET_PREFIX}as
  export AR=${TARGET_PREFIX}ar
  export NM=${TARGET_PREFIX}nm
  export RANLIB=${TARGET_PREFIX}ranlib
  export OBJCOPY=${TARGET_PREFIX}objcopy
  export OBJDUMP=${TARGET_PREFIX}objdump
  export STRIP=${TARGET_PREFIX}strip
  export WINDRES=${TARGET_PREFIX}windres
  
  NEW_PATH=
  for i in `echo $PATH | tr ':' ' '`; do
      if (echo $i | grep -v "$TOOLCHAIN/bin" >/dev/null) && (echo $i | grep -v "$TOOLCHAIN/sbin" >/dev/null); then
          NEW_PATH="${NEW_PATH}${i}:"
      fi
  done
  NEW_PATH="${NEW_PATH}/usr/bin"

  export PATH=$NEW_PATH
  cd ..
  p=`pwd`
  $PKG_CONFIGURE_SCRIPT CC=$CC \
                        LD=$LD \
                        AS=$AS \
                        AR=$AR \
                        NM=$NM \
                        RANLIB=$RANLIB \
                        OBJCOPY=$OBJCOPY \
                        OBJDUMP=$OBJDUMP \
                        STRIP=$STRIP \
                        WINDRES=$WINDRES \
                        CFLAGS="-I$ROOT/$TOOLCHAIN/mingw32/include" \
                        INCLUDES="-I$ROOT/$TOOLCHAIN/mingw32/include" \
                        CPPFLAGS="-D__386__ -D__MINGW32__ -D__MSVCRT_VERSION__=0x801 -m32 -static -I$ROOT/$TOOLCHAIN/mingw32/include" \
                        LDFLAGS="-m32 -static -L$ROOT/$TOOLCHAIN/mingw32/lib" \
                        LIBS='-lcomdlg32' \
                        --host=$TARGET_NAME \
                        --prefix=$p
  cd -
}

make_host() {
  unset -v CC
  unset -v CXX
  unset -v CFLAGS
  unset -v CXXFLAGS
  unset -v LDFLAGS
  unset -v LDLIBS
  unset -v AR
  unset -v AS
  unset -v DLLTOOL
  unset -v LD
  unset -v NM
  unset -v OBJCOPY
  unset -v RANLIB
  unset -v STRIP
  unset -v TARGET_CPP
  
  export TARGET_NAME=i386-pc-mingw32
  export TARGET_PREFIX=$ROOT/$TOOLCHAIN/mingw32/bin/$TARGET_NAME-
  export CC=${TARGET_PREFIX}gcc
  export LD=${TARGET_PREFIX}ld
  export AS=${TARGET_PREFIX}as
  export AR=${TARGET_PREFIX}ar
  export NM=${TARGET_PREFIX}nm
  export RANLIB=${TARGET_PREFIX}ranlib
  export OBJCOPY=${TARGET_PREFIX}objcopy
  export OBJDUMP=${TARGET_PREFIX}objdump
  export STRIP=${TARGET_PREFIX}strip
  export WINDRES=${TARGET_PREFIX}windres

  NEW_PATH=
  for i in `echo $PATH | tr ':' ' '`; do
      if (echo $i | grep -v "$TOOLCHAIN/bin" >/dev/null) && (echo $i | grep -v "$TOOLCHAIN/sbin" >/dev/null); then
          NEW_PATH="${NEW_PATH}${i}:"
      fi
  done
  NEW_PATH="${NEW_PATH}/usr/bin"

  export PATH=$NEW_PATH
  cd ..
  make  CC=$CC \
        LD=$LD \
        AS=$AS \
        AR=$AR \
        NM=$NM \
        RANLIB=$RANLIB \
        OBJCOPY=$OBJCOPY \
        OBJDUMP=$OBJDUMP \
        STRIP=$STRIP \
        WINDRES=$WINDRES \
        INCLUDES="-I$ROOT/$TOOLCHAIN/mingw32/include" \
        CPPFLAGS="-D__386__ -D__MINGW32__ -D__MSVCRT_VERSION__=0x801 -m32 -static -I$ROOT/$TOOLCHAIN/mingw32/include" \
        LDFLAGS="-m32 -static -L$ROOT/$TOOLCHAIN/mingw32/lib" \
        LIBS='-lcomdlg32' \
       -j1
  cd -
}

makeinstall_host() {
  cd ..
  mkdir -p $ROOT/$PACKAGES/tools/syslinux/files/3rdparty/format
  cp src/rufus.exe $ROOT/$PACKAGES/tools/syslinux/files/3rdparty/format/antiprism-fmt.exe
  cd -
}

make_target() {
 :
}
makeinstall_target() {
 :
}
