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

PKG_NAME="i2pd"
PKG_VERSION="2.9.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://bitbucket.org/orignal/i2pd"
PKG_URL="https://github.com/PurpleI2P/${PKG_NAME}/archive/${PKG_VERSION}.zip"
PKG_DEPENDS_TARGET="boost"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="I2P router written in C++"
PKG_LONGDESC="I2P router written in C++"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

post_unpack() {
  # patching Makefile as we are using multi-threading version of boost
  sed -ie 's/-lboost_[a-z0-9_]\+/&-mt/g' "$BUILD/${PKG_NAME}-${PKG_VERSION}/Makefile.linux"
}

unpack() {
  local FILE="`basename $PKG_URL`"
  [ ! -d "$SOURCES/$PKG_NAME" -o ! -f "$SOURCES/$PKG_NAME/$FILE" ] && exit 1
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"; rm -rf "$PKG_NAME-$PKG_VERSION"; unzip -o "$sourceDir/$FILE")
}

make_target() {
  make USE_STATIC=no USE_AESNI=no USE_UPNP=1 all
}

makeinstall_target() {
  rm -rf "$INSTALL/usr/lib/i2pd"
  mkdir -p "$INSTALL/usr/lib/i2pd"
  mkdir -p "$INSTALL/usr/bin"
  cp "$ROOT/$PKG_BUILD/i2pd" "$INSTALL/usr/lib/i2pd"
  if test -d "$ROOT/$PKG_BUILD/contrib"; then
    (cd "$ROOT/$PKG_BUILD/contrib"; tar cf - *) \
      | (cd "$INSTALL/usr/lib/i2pd"; tar xf -)
  fi
  cat >"$INSTALL/usr/bin/i2pd-run" <<EOF
#!/bin/bash
# An i2pd daemon launcher

HOME=\$I2PCONFIG
export HOME
uselog=none
if test "\$USE_LOG" = "1"; then uselog=file; fi
exec /usr/lib/i2pd/i2pd \
    --conf=/usr/lib/i2pd/i2pd.conf \
    --http.address=0.0.0.0 \
    --http.port=7657 \
    --httpproxy.address=0.0.0.0 \
    --httpproxy.port=4444 \
    --port=24895 \
    --tunconf=/usr/lib/i2pd/tunnels.cfg \
    --daemon \
    --log=\$uselog \
    >/dev/null &
EOF
  chmod +x "$INSTALL/usr/bin/i2pd-run"
  cat >"$INSTALL/usr/lib/i2pd/tunnels.cfg" <<EOF1
[postman-pop]
type=client
port=7660
destination=pop.postman.i2p

[postman-smtp]
type=client
port=7659
destination=smtp.postman.i2p

[eepsite-in]
type=http
host=127.0.0.1
port=8080
inport=80
keys=privKeys.dat
EOF1

cat >"$INSTALL/usr/lib/i2pd/subscriptions.txt" <<EOF2
http://i2p-projekt.i2p/hosts.txt
http://inr.i2p/export/alive-hosts.txt
EOF2
cat >"$INSTALL/usr/lib/i2pd/i2pd.conf" <<EOF3
EOF3

  cp $PKG_DIR/config/* "$INSTALL/usr/lib/i2pd"
}

