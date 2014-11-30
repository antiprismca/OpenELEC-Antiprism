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

PKG_NAME="i2p"
PKG_VERSION="0.9.16"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://i2p2.de"
PKG_URL="https://download.i2p2.de/releases/${PKG_VERSION}/${PKG_NAME}source_${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="openjdk"
PKG_BUILD_DEPENDS_TARGET="openjdk"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="The Invisible Internet Project"
PKG_LONGDESC="The I2P network provides strong privacy protections for communication over the Internet. Many activities that would risk your privacy on the public Internet can be conducted anonymously inside I2P."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

post_unpack() {
  if test ! -d "$BUILD/${PKG_NAME}-${PKG_VERSION}"; then
    echo "Unpack failed: $PKG_NAME"
    exit 1
  fi
  rm -rf $BUILD/i2p.i2p
  (cd $BUILD; ln -s "${PKG_NAME}-${PKG_VERSION}" i2p.i2p)
}

make_target() {
  test -n "$ANT_HOME" || ANT_HOME="`which ant | sed s%/bin/ant\$%% 2>/dev/null`"
  test -n "$JAVA_HOME" || JAVA_HOME="`which java | sed s%/bin/java\$%% 2>/dev/null`"
  rm -f i2p.tar.bz2
  PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH \
    $ANT_HOME/bin/ant tarball 
}

post_make_target() {
  test -n "$ANT_HOME" || ANT_HOME="`which ant | sed s%/bin/ant.*\$%% 2>/dev/null`"
  local antJar="$ANT_HOME/lib/ant.jar"
  if test ! -f "$antJar"; then
    echo "ant.jar is not found at path $antJar! Have you set ANT_HOME?"
    exit 1
  fi
  cp "$antJar" apps/jetty/jettylib
}

replace_paths() {
  local file_name=$1
  sed -i 's#%INSTALL_PATH#/usr/lib/i2p#g;s#%SYSTEM_java_io_tmpdir#/tmp#g;s#%PROFILE_PATH#/storage/.Profile#g' "$file_name"
}

replace_rules() {
  sed -i 's#clientApp\.0\.args\=7657\ \:\:1\,127\.0\.0\.1#\#clientApp.0.args=7657 ::1,127.0.0.1#g;s#\#clientApp\.0\.args\=7657\ 0\.0\.0\.0#clientApp.0.args=7657 0.0.0.0#g;s#\#clientApp\.0\.args\=7657\ \:\:\ #clientApp.0.args=7657 :: #g' clients.config
  sed -i 's#interface\=127\.0\.0\.1#interface=0.0.0.0#g' i2ptunnel.config
}

makeinstall_target() {
  if test ! -f "$ROOT/$PKG_BUILD/i2p.tar.bz2"; then echo "$ROOT/$PKG_BUILD/i2p.tar.bz2 does not exist!" >&2; exit 3; fi
  mkdir -p "$INSTALL/usr/lib"
  (cd $INSTALL/usr/lib; tar xjf "$ROOT/$PKG_BUILD/i2p.tar.bz2")
  if test -d "$INSTALL/usr/lib/i2p"; then
    (cd "$INSTALL/usr/lib/i2p"; \
      echo "echo ${TARGET_NAME}" >./osid; \
      bash ./postinstall.sh; \
      replace_paths eepget; \
      replace_paths i2prouter; \
      replace_paths i2psvc; \
      replace_paths runplain.sh; \
      replace_rules)
    mkdir -p "$INSTALL/usr/bin"
    (cd "$INSTALL/usr/bin"; \
      ln -s ../lib/i2p/eepget ../lib/i2p/i2prouter ../lib/i2p/i2psvc .; \
      ln ../lib/i2p/runplain.sh i2p-runplain)
  fi
  mkdir -p $SYSROOT_PREFIX/usr/lib
  (cd $SYSROOT_PREFIX/usr/lib; tar xjf "$ROOT/$PKG_BUILD/i2p.tar.bz2")
}

