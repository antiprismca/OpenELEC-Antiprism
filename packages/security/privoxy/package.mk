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

PKG_NAME="privoxy"
PKG_VERSION="3.0.23-stable"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.privoxy.org"
# PKG_URL="http://hivelocity.dl.sourceforge.net/project/ijbswa/Sources/3.0.21%20%28stable%29/privoxy-3.0.21-stable-src.tar.gz"
PKG_URL="http://heanet.dl.sourceforge.net/project/ijbswa/Sources/3.0.23%20%28stable%29/privoxy-3.0.23-stable-src.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="Privoxy"
PKG_LONGDESC=""

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

configure_target() {
  cd $ROOT/$PKG_BUILD
  autoheader
  autoconf
  ./configure --host=$ARCH-unknown-linux-gnu
  cd -
}

make_target() {
  cd $ROOT/$PKG_BUILD
  make
  cd -
}

makeinstall_target() {
  cd $ROOT/$PKG_BUILD
  mkdir -p $INSTALL/usr
  mkdir -p $INSTALL/usr/bin
  mkdir -p $INSTALL/etc
  mkdir -p $INSTALL/etc/privoxy
  mkdir -p $INSTALL/etc/privoxy/templates
  cp privoxy $INSTALL/usr/bin/
  ${TARGET_STRIP} $INSTALL/usr/bin/privoxy
  sed -e "s/listen-address\ \ 127.0.0.1:8118/listen-address  0.0.0.0:8118/g" -e "s/confdir\ \./confdir\ \/etc\/privoxy/g" -e "s/logdir\ \./logdir\ \/var\/log\/privoxy/g" config > $INSTALL/etc/privoxy/config
  echo "forward-socks5	/	127.0.0.1:1080 ." >> $INSTALL/etc/privoxy/config
  echo "forward	.i2p	127.0.0.1:4444" >> $INSTALL/etc/privoxy/config
  echo "forward         192.168.*.*/     ." >> $INSTALL/etc/privoxy/config
  echo "forward            10.*.*.*/     ." >> $INSTALL/etc/privoxy/config
  echo "forward           127.*.*.*/     ." >> $INSTALL/etc/privoxy/config
  cp default.action $INSTALL/etc/privoxy
  cp default.filter $INSTALL/etc/privoxy
  cp match-all.action $INSTALL/etc/privoxy
  cp trust $INSTALL/etc/privoxy
  cp user.action $INSTALL/etc/privoxy
  cp user.filter $INSTALL/etc/privoxy
  cp templates/* $INSTALL/etc/privoxy/templates
  cd -
}


