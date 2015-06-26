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

PKG_NAME="x86-mingw32-build"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_SITE="http://www.mingw.org"
PKG_URL="http://sourceforge.net/projects/mingw/files/Other/Cross-Hosted%20MinGW%20Build%20Tool/${PKG_NAME}-${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}-sh.tar.bz2"
PKG_PRIORITY="optional"
PKG_SECTION="devel"
PKG_SHORTDESC="MinGW - Minimalist GNU for Windows"
PKG_LONGDESC="MinGW provides a complete Open Source programming tool set which is suitable for the development of native MS-Windows applications, and which do not depend on any 3rd-party C-Runtime DLLs. "

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

post_patch() {
  cd `echo "$PKG_BUILD" | cut -f1 -d\ `
  p=`pwd`
  sed -i "s#@HOME@#${p}#g" x86-mingw32-build.sh.conf
  sed -i "s#@TOOLCHAIN@#${ROOT}/${TOOLCHAIN}#g" x86-mingw32-build.sh.conf
  sed -i "s#@SOURCES@#${ROOT}/${SOURCES}/${PKG_NAME}#g" x86-mingw32-build.sh.conf
  cd -
}

configure_host() {
  :
}

make_host() {
  unset -v CC
  unset -v CXX
  unset -v CFLAGS
  unset -v CXXFLAGS
  unset -v LDFLAGS
  unset -v LDLIBS
  unset -v AR
  unset -v AS
  unset -v DLLTOOL
  unset -v LD
  unset -v NM
  unset -v OBJCOPY
  unset -v RANLIB
  unset -v STRIP
  
  TARGET_NAME=i386-pc-mingw32
  
  bash x86-mingw32-build.sh $TARGET_NAME
}

makeinstall_host() {
  :
}
