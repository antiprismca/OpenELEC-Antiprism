
PKG_NAME="meek"
PKG_VERSION="0.25"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_DEPENDS_TARGET="toolchain go"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="Meek is a pluggable transport proxy written in Go."
PKG_LONGDESC=""

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

get_go_arch() {
  case $1 in
  i386*|i486*|i586*|i686*)
    echo "386";;
  x86_64*)
    echo "amd64";;
  arm*)
    echo "arm";;
  *)
    echo "unknown";;
  esac
}

unpack() {
  [ -d $ROOT/$PKG_BUILD/meek-client ] || git clone https://git.torproject.org/pluggable-transports/meek.git $ROOT/$PKG_BUILD
  cd $ROOT/$PKG_BUILD
  git checkout $PKG_VERSION
  cd -
}

make_target() {
  BIN_GO=$SYSROOT_PREFIX/usr/share/gopath/bin/go
  cd $ROOT/$PKG_BUILD/meek-client
  export GOHOSTARCH=$(get_go_arch $HOST_NAME)
  export GOARCH=$(get_go_arch $TARGET_NAME)
  export GOPATH=$SYSROOT_PREFIX/usr/share/gopath
  echo "GOPATH=$GOPATH"
  $BIN_GO get git.torproject.org/pluggable-transports/goptlib.git
  $BIN_GO build -i -p 1 -v .
  $STRIP meek-client
  cd -
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp -f $ROOT/$PKG_BUILD/meek-client/meek-client $INSTALL/usr/bin
}

