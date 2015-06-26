
PKG_NAME="python-bitcoinrpc"
PKG_VERSION="0.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://pypi.python.org/pypi/python-bitcoinrpc"
PKG_URL="http://pypi.python.org/packages/source/p/python-bitcoinrpc/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python distutilscross:host bitcoin"
PKG_PRIORITY="optional"
PKG_SECTION="python/system"
PKG_SHORTDESC="python-bitcoinrpc"
PKG_LONGDESC="python-bitcoinrpc: enhanced version of python-jsonrpc for use with Bitcoin"

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
  rm -rf $INSTALL/usr/lib/python*/site-packages/*/tests
}
