
PKG_NAME="fte"
PKG_VERSION="0.1.3"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/kpdyer/libfte"
PKG_URL="https://pypi.python.org/packages/a1/0f/3c535bd0783f116113b103284550d2a904e5bfb5c6e728709cf7abd71b34/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python distutilscross:host gmp"
PKG_PRIORITY="optional"
PKG_SECTION="python/web"
PKG_SHORTDESC="Format-Transforming Encryption"
PKG_LONGDESC=""

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

pre_make_target() {
  export PYTHONXCPREFIX="$SYSROOT_PREFIX/usr"
  export CFLAGS="-I$ROOT/$TOOLCHAIN/include"
}

make_target() {
  export CC=$TARGET_CXX
  python setup.py build --cross-compile
}

makeinstall_target() {
  python setup.py install --root=$INSTALL --prefix=/usr
}

post_makeinstall_target() {
  find $INSTALL/usr/lib -name "*.py" -exec rm -rf "{}" ";"
  rm -rf $INSTALL/usr/lib/python*/site-packages/*/test
}
