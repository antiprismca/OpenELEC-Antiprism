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

PKG_NAME="i2p.Seedless"
PKG_VERSION="0.1.7-0.1.12"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://sponge.i2p"
PKG_URL="https://github.com/trundens/$PKG_NAME/archive/$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="neodatis-odb i2p"
PKG_BUILD_DEPENDS_TARGET="toolchain neodatis-odb i2p"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="Seedless plugin by sponge"
PKG_LONGDESC="Seedless core and console plugin is a self-seeding seed information spreader for I2P, unpublished eepsite and resource (i2pbote peers, torrents etc) locator"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; unzip -o "$sourceDir/$FILE")
}

configure_target() {
  echo "Configuring $PKG_SHORTDESC"
  # do nothing
}

pre_make_target() {
  local neodatisJar="$SYSROOT_PREFIX/usr/lib/i2p/lib/neodatis.jar"
  if test ! -f "$neodatisJar"; then
    echo "Neodatis jar is not found at path $neodatisJar"
    exit 1
  fi
  cp "$neodatisJar" lib
  echo "Neodatis jar copied"
}

make_target() {
  test -n "$ANT_HOME" || ANT_HOME="`which ant | sed s%/bin/ant\$%% 2>/dev/null`"
  test -n "$JAVA_HOME" || JAVA_HOME="`which java | sed s%/bin/java\$%% 2>/dev/null`"
  rm -rf dist
  PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH \
    $ANT_HOME/bin/ant --noconfig dist 
}

makeinstall_target() {
  [ ! -f "dist/webapps/SeedlessConsole.war" -o ! -f "dist/NeodatisClassIncluder.jar" -o ! -f "dist/lib/SeedlessCoreClassIncluder.jar" ] && exit 1

  rm -rf "$INSTALL/usr/lib/i2p/dist-plugins/plugins/01_neodatis"
  rm -rf "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless"

  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/01_neodatis"
  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/01_neodatis/lib"
  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless"
  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless/lib"
  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless/console/webapps"

  cp "plugins/01_neodatis/clients.config" \
     "plugins/01_neodatis/plugin.config" \
     "plugins/01_neodatis/webapps.config" \
     "$INSTALL/usr/lib/i2p/dist-plugins/plugins/01_neodatis"
  cp "dist/NeodatisClassIncluder.jar" \
     "neodatis/dist/lib/lib/neodatis.jar" \
     "$INSTALL/usr/lib/i2p/dist-plugins/plugins/01_neodatis/lib"

  cp "plugins/02_seedless/clients.config" \
     "plugins/02_seedless/plugin.config" \
     "plugins/02_seedless/webapps.config" \
     "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless"
  cp "dist/lib/SeedlessCoreClassIncluder.jar" \
     "dist/lib/SeedlessCore.jar" \
     "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless/lib"
  cp "dist/webapps/SeedlessConsole.war" \
     "$INSTALL/usr/lib/i2p/dist-plugins/plugins/02_seedless/console/webapps"
}

