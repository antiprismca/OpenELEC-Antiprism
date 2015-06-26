
PKG_NAME="bitcoin"
PKG_VERSION="0.10.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="https://bitcoin.org/"
PKG_URL="https://bitcoin.org/bin/bitcoin-core-$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain db boost"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="Bitcoin Core"
PKG_LONGDESC="Bitcoin is an experimental new digital currency that enables instant payments to anyone, anywhere in the world. Bitcoin uses peer-to-peer technology to operate with no central authority: managing transactions and issuing money are carried out collectively by the network. Bitcoin Core is the name of open source software which enables the use of this currency."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

export TARGET_CFLAGS="$TARGET_CFLAGS -I$SYSROOT_PREFIX/usr/include/boost -L$SYSROOT_PREFIX/usr/lib"

make_target() {
  cd $ROOT/$PKG_BUILD
  ./configure \
    --host=${TARGET_NAME} \
    --prefix=/usr \
    --with-boost=$SYSROOT_PREFIX/usr \
    --with-boost-libdir=$SYSROOT_PREFIX/usr/lib \
    --with-boost-system=boost_system-mt \
    --with-boost-filesystem=boost_filesystem-mt \
    --with-boost-thread=boost_thread-mt \
    --with-boost-program-options=boost_program_options-mt \
    --with-boost-chrono=boost_chrono-mt \
    --with-boost-unit-test-framework=boost_unit_test_framework-mt \
    --srcdir=$ROOT/$PKG_BUILD/
    
  make -C $ROOT/$PKG_BUILD/src
  cd -
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/bitcoind $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/bitcoin-tx $INSTALL/usr/bin
  cp $ROOT/$PKG_BUILD/src/bitcoin-cli $INSTALL/usr/bin
}

post_makeinstall_target() {
  ${TARGET_STRIP} "$INSTALL/usr/bin/bitcoind"
  ${TARGET_STRIP} "$INSTALL/usr/bin/bitcoin-tx"
  ${TARGET_STRIP} "$INSTALL/usr/bin/bitcoin-cli"
}

