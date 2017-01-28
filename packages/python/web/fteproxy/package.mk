
PKG_NAME="fteproxy"
PKG_VERSION="0.2.18-src"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://fteproxy.org"
PKG_URL="https://fteproxy.org/dist/0.2.18/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python distutilscross:host obfsproxy fte"
PKG_PRIORITY="optional"
PKG_SECTION="python/web"
PKG_SHORTDESC="Fteproxy is a pluggable transport proxy written in Python."
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
  mkdir -p $INSTALL/bin
  cp -f $ROOT/$PKG_BUILD/bin/fteproxy $INSTALL/bin
}

post_makeinstall_target() {
  find $INSTALL/usr/lib -name "*.py" -exec rm -rf "{}" ";"
  rm -rf $INSTALL/usr/bin
  # rm -rf $INSTALL/usr/lib/python*/site-packages/*/test
}
