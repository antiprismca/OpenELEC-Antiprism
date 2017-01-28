
PKG_NAME="go"
PKG_VERSION="1.7.3"
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
  local PACKAGE="$PKG_NAME-$1"
  if (test ! -d "$ROOT/$SOURCES/$PKG_NAME") || (test ! -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz); then
    rm -rf $ROOT/$SOURCES/$PKG_NAME/$1
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.md5
    rm -f $ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.url
    mkdir -p $ROOT/$SOURCES/$PKG_NAME/$1
    (cd $ROOT/$SOURCES/$PKG_NAME/$1
    git clone https://go.googlesource.com/go
    (cd go; git checkout go$1)
    mv go $PACKAGE
    tar czf ../$PACKAGE.tar.gz $PACKAGE)
    echo 'https://go.googlesource.com/go' >$ROOT/$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.url
    (cd $ROOT; md5sum -t $SOURCES/$PKG_NAME/$PACKAGE.tar.gz >$SOURCES/$PKG_NAME/$PACKAGE.tar.gz.md5)
  fi
}

download_and_unpack() {
  download $1
  local PACKAGE="$PKG_NAME-$1"
  local PKG_BUILD="$BUILD/$PKG_NAME-$1"
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

unpack() {
  download_and_unpack 1.4.3
  download_and_unpack $PKG_VERSION
}

post_patch() {
  cd $ROOT/$PKG_BUILD/src/net
  sed -ie 's#"/etc/resolv.conf"#getResolvConfPath()#g' *.go
  cd -
}

pre_configure_target() {
  unpack
  cd $ROOT/$PKG_BUILD/src/syscall
  ./mksyscall.pl -l32 syscall_linux.go syscall_linux_386.go > zsyscall_linux_386.go
  ./mksyscall.pl syscall_linux.go syscall_linux_amd64.go > zsyscall_linux_amd64.go
  ./mksyscall.pl -l32 -arm syscall_linux.go syscall_linux_arm.go > zsyscall_linux_arm.go
  ./mksyscall.pl syscall_linux.go syscall_linux_arm64.go > zsyscall_linux_arm64.go
  cd -
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
  export LDFLAGS=`echo $LDFLAGS | sed -e "s|-fuse-ld=gold||g"`
  OLDPATH="$PATH"
  local PKG_BUILD="$BUILD/$PKG_NAME-1.4.3"
  cd $ROOT/$PKG_BUILD/src
  . ./make.bash "$@" --no-banner
  PATH="$OLDPATH"
  $GOTOOLDIR/dist banner
  install_go 1.4.3
  OLDPATH="$PATH"
  PKG_BUILD="$BUILD/$PKG_NAME-$PKG_VERSION"
  export GOROOT_BOOTSTRAP=$SYSROOT_PREFIX/usr/share/gopath
  export GO_DISTFLAGS=""
  cd $ROOT/$PKG_BUILD/src
  . ./make.bash "$@" --no-banner 
  PATH="$OLDPATH"
  $GOTOOLDIR/dist banner
  install_go $PKG_VERSION)
}
  
install_go() {
  local PKG_BUILD="$BUILD/$PKG_NAME-$1"
  # $STRIP $ROOT/$PKG_BUILD/bin/go

  echo "Installing go into $SYSROOT_PREFIX/usr/share/go"
  rm -rf $SYSROOT_PREFIX/usr/share/go
  mkdir -p $SYSROOT_PREFIX/usr/share/go
  (cd $ROOT/$PKG_BUILD
   tar cf - bin lib misc pkg src) | 
   (cd $SYSROOT_PREFIX/usr/share/go
    tar xf -)
  echo "Installing go into $SYSROOT_PREFIX/usr/share/gopath"
  rm -rf $SYSROOT_PREFIX/usr/share/gopath
  mkdir -p $SYSROOT_PREFIX/usr/share/gopath
  (cd $ROOT/$PKG_BUILD
   tar cf - bin lib misc pkg src) | 
   (cd $SYSROOT_PREFIX/usr/share/gopath
    tar xf -)
}

makeinstall_target() {
 :
}

