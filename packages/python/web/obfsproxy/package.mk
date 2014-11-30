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

PKG_NAME="obfsproxy"
PKG_VERSION="0.2.12"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://pypi.python.org/pypi/obfsproxy"
PKG_URL="https://pypi.python.org/packages/source/o/obfsproxy/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_HOST="pycrypto"
PKG_DEPENDS_TARGET="toolchain Python distutilscross:host PyYAML zope.interface Twisted pyptlib pycrypto"
PKG_PRIORITY="optional"
PKG_SECTION="python/web"
PKG_SHORTDESC="Obfsproxy is a pluggable transport proxy written in Python."
PKG_LONGDESC="If you want to write a pluggable transport, see the code of already existing transports in obfsproxy/transports/ . Unfortunately a coding guide for pluggable transport authors does not exist at the moment!"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

pre_make_target() {
  export PYTHONXCPREFIX="$SYSROOT_PREFIX/usr"
}

make_target() {
  python setup.py build --cross-compile
}

makeinstall_target() {
  python setup.py install --root=$INSTALL --prefix=/usr
}

post_makeinstall_target() {
  find $INSTALL/usr/lib -name "*.py" -exec rm -rf "{}" ";"
  rm -rf $INSTALL/usr/lib/python*/site-packages/*/test
  cp -f $ROOT/$PKG_BUILD/bin/obfsproxy $INSTALL/usr/bin 
}
