
PKG_NAME="go"
PKG_VERSION="1.4.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="BSD"
PKG_SITE="https://golang.org/"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="lang"
PKG_SHORTDESC="go: Golang compiler"
PKG_LONGDESC="Go is an open source programming language that makes it easy to build simple, reliable, and efficient software."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

download() {
  local PACKAGE="$PKG_NAME-$PKG_VERSION"
  if (test ! -d "$ROOT/$SOURCES/$PKG_NAME") || (test ! -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz); then
    rm -rf $ROOT/$SOURCES/$PKG_NAME/tmp
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.md5
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.url
    mkdir -p $ROOT/$SOURCES/$PKG_NAME/tmp
    (cd $ROOT/$SOURCES/$PKG_NAME/tmp
    git clone https://go.googlesource.com/go
    (cd go; git checkout go${PKG_VERSION})
    mv go $PACKAGE
    tar czf ../$PACKAGE.tar.gz $PACKAGE)
    echo 'https://go.googlesource.com/go' >$ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.url
    (cd $ROOT/$SOURCES/$PKG_NAME; md5sum -t $PACKAGE.tar.gz >$PACKAGE.tar.gz.md5)
  fi
}

unpack() {
  local PACKAGE="$PKG_NAME-$PKG_VERSION"
  if (test ! -d "$ROOT/$PKG_BUILD") || (test ! -f "$ROOT/$PKG_BUILD/.openelec-unpack"); then
    (cd "$ROOT/$BUILD"
    rm -rf $PACKAGE
    tar xzf $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz
    cd $ROOT/$PKG_BUILD
    rm -rf ".openelec-unpack"
    for i in PKG_NAME PKG_VERSION PKG_REV PKG_SHORTDESC PKG_LONGDESC PKG_SITE PKG_URL PKG_SECTION; do
      eval val=\$$i
      echo "STAMP_$i=\"$val"\" >>".openelec-unpack"
    done)
  fi
}

pre_configure_target() {
  download
  unpack
}

configure_target() {
 : # do nothing
}

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

make_target() {
  (GOROOT_FINAL=$SYSROOT_PREFIX/usr/share/go
  export GOHOSTARCH=$(get_go_arch $HOST_NAME)
  export GOARCH=$(get_go_arch $TARGET_NAME)
  export CC=$HOST_CC
  export CXX=$HOST_CCXX
  export CC_FOR_TARGET=$TARGET_CC
  export CXX_FOR_TARGET=$TARGET_CXX
  export GO_DISTFLAGS="-s"
  export CGO_ENABLED=0
  export GO_EXTLINK_ENABLED=0
  CFLAGS=
  CXXFLAGS=
  cd $ROOT/$PKG_BUILD/src
  OLDPATH="$PATH"
  export LDFLAGS=`echo $LDFLAGS | sed -e "s|-fuse-ld=gold||g"`
  . ./make.bash "$@" --no-banner
  PATH="$OLDPATH"
  $GOTOOLDIR/dist banner)
  
  # $STRIP $ROOT/$PKG_BUILD/bin/go

  echo "Installing go into $SYSROOT_PREFIX/usr/share/go"
  rm -rf $SYSROOT_PREFIX/usr/share/go
  mkdir -p $SYSROOT_PREFIX/usr/share/go
  (cd $ROOT/$PKG_BUILD
   tar cf - bin include lib misc pkg src) | 
   (cd $SYSROOT_PREFIX/usr/share/go
    tar xf -)
  echo "Installing go into $SYSROOT_PREFIX/usr/share/gopath"
  rm -rf $SYSROOT_PREFIX/usr/share/gopath
  mkdir -p $SYSROOT_PREFIX/usr/share/gopath
  (cd $ROOT/$PKG_BUILD
   tar cf - bin include lib misc pkg src) | 
   (cd $SYSROOT_PREFIX/usr/share/gopath
    tar xf -)
}

makeinstall_target() {
 :
}

