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

PKG_NAME="tor"
PKG_VERSION="0.2.9.8"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://www.torproject.org"
PKG_URL="https://www.torproject.org/dist/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="libressl zlib miniupnpc Libevent"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="The Tor Project"
PKG_LONGDESC="Tor protects your privacy on the internet by hiding the connection between your Internet address and the services you use. We believe Tor is reasonably secure, but please ensure you read the instructions and configure it properly"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_TARGET="\
              --enable-upnp \
              --enable-libevent \
              --disable-gcc-hardening"

post_install() {
  add_user tor x 990 990 "Tor Server" "/storage" "/bin/sh"
  add_group tor 990
}
