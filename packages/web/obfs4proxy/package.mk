
PKG_NAME="obfs4proxy"
PKG_VERSION="0.0.7"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_URL="https://github.com/Yawning/obfs4/archive/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain go"
PKG_PRIORITY="optional"
PKG_SECTION="web"
PKG_SHORTDESC="Obfs4proxy is a pluggable transport proxy written in Go."
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

post_unpack() {
  [ -d "$BUILD/obfs4-$PKG_NAME-$PKG_VERSION" ] && mv "$BUILD/obfs4-$PKG_NAME-$PKG_VERSION" "$BUILD/$PKG_NAME-$PKG_VERSION"
}

make_target() {
  BIN_GO=$SYSROOT_PREFIX/usr/share/gopath/bin/go
#  [ -d $ROOT/$PKG_BUILD/obfs4proxy ] || git clone https://git.torproject.org/pluggable-transports/obfs4.git $ROOT/$PKG_BUILD
  cd $ROOT/$PKG_BUILD/obfs4proxy
  export GOHOSTARCH=$(get_go_arch $HOST_NAME)
  export GOARCH=$(get_go_arch $TARGET_NAME)
  export GOPATH=$SYSROOT_PREFIX/usr/share/gopath
  echo "GOPATH=$GOPATH"
#  $BIN_GO get -v ./...
  $BIN_GO get golang.org/x/net/proxy
  $BIN_GO get github.com/menghan/docker/vendor/src/code.google.com/p/go.net/proxy
  $BIN_GO get git.torproject.org/pluggable-transports/obfs4.git/transports
  $BIN_GO build -i -p 1 -v .
  $STRIP obfs4proxy
  cd -
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp -f $ROOT/$PKG_BUILD/obfs4proxy/obfs4proxy $INSTALL/usr/bin
}

