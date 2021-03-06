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

PKG_NAME="ncurses"
PKG_VERSION="5.9"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="http://www.gnu.org/software/ncurses/"
PKG_URL="http://ftp.gnu.org/pub/gnu/ncurses/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses:host zlib"
PKG_PRIORITY="optional"
PKG_SECTION="devel"
PKG_SHORTDESC="ncurses: The ncurses (new curses) library"
PKG_LONGDESC="The ncurses (new curses) library is a free software emulation of curses in System V Release 4.0, and more. It uses terminfo format, supports pads and color and multiple highlights and forms characters and function-key mapping, and has all the other SYSV-curses enhancements over BSD curses."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_HOST="--target=$TARGET_NAME --without-gpm"
PKG_CONFIGURE_OPTS_TARGET="--without-ada \
                           --without-cxx \
                           --without-cxx-binding \
                           --disable-db-install \
                           --without-manpages \
                           --without-progs \
                           --without-tests \
                           --with-curses-h \
                           --without-shared \
                           --with-normal \
                           --without-debug \
                           --without-profile \
                           --with-termlib \
                           --without-ticlib \
                           --without-gpm \
                           --without-dbmalloc \
                           --without-dmalloc \
                           --disable-rpath \
                           --disable-overwrite \
                           --disable-database \
                           --with-fallbacks=linux,screen,xterm,xterm-color \
                           --disable-big-core \
                           --enable-termcap \
                           --enable-getcap \
                           --enable-getcap-cache \
                           --enable-symlinks \
                           --disable-bsdpad \
                           --without-rcs-ids \
                           --enable-ext-funcs \
                           --disable-const \
                           --enable-no-padding \
                           --disable-sigwinch \
                           --disable-tcap-names \
                           --without-develop \
                           --disable-hard-tabs \
                           --disable-xmc-glitch \
                           --disable-hashmap \
                           --disable-safe-sprintf \
                           --disable-scroll-hints \
                           --disable-widec \
                           --disable-echo \
                           --disable-warnings \
                           --disable-home-terminfo \
                           --disable-assertions LIBS= "

pre_configure_target() {
  # causes some segmentation fault's (dialog) when compiled with gcc's link time optimization.
  strip_lto
}

make_host() {
  make -C include
  make -C progs tic
}

makeinstall_host() {
  cp progs/tic $ROOT/$TOOLCHAIN/bin
#  cp lib/*.so* $ROOT/$TOOLCHAIN/lib
  make -C include install
}

make_target() {
  export LIBS=
  make -C include
  make -C ncurses
}

post_makeinstall_target() {
  cp misc/ncurses-config $ROOT/$TOOLCHAIN/bin
    chmod +x $ROOT/$TOOLCHAIN/bin/ncurses-config
    $SED "s:\(['=\" ]\)/usr:\\1$SYSROOT_PREFIX/usr:g" $ROOT/$TOOLCHAIN/bin/ncurses-config

  make DESTDIR=$INSTALL -C ncurses install
  cp lib/*.a $SYSROOT_PREFIX/lib
  
  mkdir -p $INSTALL/usr/share/terminfo/l
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe linux \
      $ROOT/$PKG_BUILD/misc/terminfo.src

  mkdir -p $INSTALL/usr/share/terminfo/s
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe screen \
      $ROOT/$PKG_BUILD/misc/terminfo.src

  mkdir -p $INSTALL/usr/share/terminfo/x
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe xterm \
      $ROOT/$PKG_BUILD/misc/terminfo.src
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe xterm-color \
      $ROOT/$PKG_BUILD/misc/terminfo.src

  mkdir -p $INSTALL/usr/share/terminfo/r
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe rxvt \
      $ROOT/$PKG_BUILD/misc/terminfo.src
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe rxvt-256color \
      $ROOT/$PKG_BUILD/misc/terminfo.src
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe rxvt-unicode \
      $ROOT/$PKG_BUILD/misc/terminfo.src
    TERMINFO=$INSTALL/usr/share/terminfo $ROOT/$TOOLCHAIN/bin/tic -xe rxvt-unicode-256color \
      $ROOT/$PKG_BUILD/misc/terminfo.src
}
