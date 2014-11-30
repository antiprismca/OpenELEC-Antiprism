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

PKG_NAME="ecc-tools"
PKG_VERSION="1.3"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://www.antiprism.ca"
PKG_WGET_AUTH="$GITHUB_AUTH"
PKG_URL="${ANTIPRISM_COMPONENTS_LOCATION}/$PKG_NAME/archive/$PKG_VERSION.zip"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="ECC Tools"
PKG_LONGDESC="ECC Tools"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; unzip -o "$sourceDir/$FILE")
}

makeinstall_target() {
  make DESTDIR="$INSTALL" install
  (cd $INSTALL
  for f in `find usr -lname '*ecc_tools*'`; do 
    rm -f $f
    ln usr/bin/ecc_tools $f
  done)

}

