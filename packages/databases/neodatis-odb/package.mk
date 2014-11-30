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

PKG_NAME="neodatis-odb"
PKG_VERSION="2.1.beta14.209"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://sourceforge.net/projects/neodatis-odb"
PKG_URL="http://downloads.sourceforge.net/project/neodatis-odb/NeoDatis%20ODB%20for%20Java/2/beta/beta14/$PKG_NAME-$PKG_VERSION.zip"
PKG_BUILD_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="databases"
PKG_SHORTDESC="NeoDatis ODB"
PKG_LONGDESC="NeoDatis ODB is a new generation Object Oriented Database. ODB is a real native and transparent persistence layer for Java, .Net, Groovy, Scala and Google Android. ODB is very simple and very fast and comes with a powerful query language."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

unpack() {
  FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd $BUILD; unzip "$sourceDir/$FILE")
}

configure_target() {
  echo "Configuring $PKG_SHORTDESC"
  # do nothing
}

make_target() {
  if test ! -d src -o ! -f src/src.jar; then
    echo "Bad source of $PKG_NAME"
    exit 1
  fi
  test -n "$ANT_HOME" || ANT_HOME="`which ant | sed s%/bin/ant\$%% 2>/dev/null`"
  test -n "$JAVA_HOME" || JAVA_HOME="`which java | sed s%/bin/java\$%% 2>/dev/null`"
  (cd src
    unzip -o src.jar
    if test ! -d ant -o ! -f ant/build.xml; then
        echo "Bad src.jar in sources of $PKG_NAME"
        exit 3
    fi
    mkdir -p src-plugins
    rm -rf dist
    PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH \
        $ANT_HOME/bin/ant -f ant/build.xml jar)
  if test $? -ne 0; then exit 3; fi
  if test ! -f "src/dist/neodatis-odb.jar"; then
    echo "Cannot build `cd src; pwd`/dist/neodatis-odb.jar!"
    exit 1
  fi
}

makeinstall_target() {
  mkdir -p "$SYSROOT_PREFIX/usr/lib/i2p/lib"
  cp "$ROOT/$PKG_BUILD/src/dist/neodatis-odb.jar" "$SYSROOT_PREFIX/usr/lib/i2p/lib/neodatis.jar"
}

