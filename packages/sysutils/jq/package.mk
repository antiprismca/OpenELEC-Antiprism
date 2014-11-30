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

PKG_NAME="jq"
PKG_VERSION="1.4"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://http://stedolan.github.io/jq/"
PKG_URL="https://github.com/stedolan/$PKG_NAME/archive/$PKG_NAME-$PKG_VERSION.zip"
PKG_DEPENDS_TARGET="flex:host bison:host"
PKG_PRIORITY="optional"
PKG_SECTION=""
PKG_SHORTDESC="jq is a command-line JSON processor"
PKG_LONGDESC="jq is like sed for JSON data – you can use it to slice and filter and map and transform structured data with the same ease that sed, awk, grep and friends let you play with text."

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"
    rm -rf "$PKG_NAME-$PKG_VERSION"
    unzip -o "$sourceDir/$FILE"
    if test -d "$PKG_NAME-$PKG_NAME-$PKG_VERSION"; then
      mv "$PKG_NAME-$PKG_NAME-$PKG_VERSION" "$PKG_NAME-$PKG_VERSION"
    fi)
}


