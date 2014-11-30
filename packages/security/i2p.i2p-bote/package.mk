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

PKG_NAME="i2p.i2p-bote"
PKG_VERSION="0.2.10-b158"
PKG_GIT_HASH="e030e9ed5f44a6a737e13ed29973893f5cd937ae"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://i2pbote.i2p"
PKG_URL="https://github.com/i2p/$PKG_NAME/archive/$PKG_GIT_HASH.zip http://z093.zebra.fastwebserver.de/apache-james-3.0-beta5-20140722-app.zip http://subethasmtp.googlecode.com/files/subethasmtp-3.1.7.zip"
PKG_DEPENDS_TARGET="i2p i2p.Seedless"
PKG_BUILD_DEPENDS_TARGET="toolchain i2p i2p.Seedless"
PKG_PRIORITY="optional"
PKG_SECTION="security"
PKG_SHORTDESC="Secure Distributed Email"
PKG_LONGDESC="I2P-Bote is a plugin for I2P that allows users to send and receive emails while preserving privacy. It does not need a mail server because emails are stored in a distributed hash table. They are automatically encrypted and digitally signed, which ensures no one but the intended recipient can read the email, and third parties cannot forge them."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

APACHE_JAMES_FILES_TO_EXTRACT="\
  apache-james-imap-api-0.4-20140521.052406-677.jar \
  apache-james-imap-message-0.4-20140521.052432-676.jar \
  apache-james-imap-processor-0.4-20140521.052450-675.jar \
  apache-james-mailbox-api-0.6-20140722.040047-433.jar \
  apache-james-mailbox-store-0.6-20140722.040110-430.jar \
  apache-mime4j-core-0.7.2.jar \
  apache-mime4j-dom-0.7.2.jar \
  commons-codec-1.5.jar \
  commons-collections-3.2.1.jar \
  commons-configuration-1.6.jar \
  commons-io-2.0.1.jar \
  commons-lang-2.6.jar \
  james-server-lifecycle-api-3.0.0-beta5-20140722.101248-779.jar \
  james-server-protocols-imap4-3.0.0-beta5-20140722.101923-649.jar \
  james-server-protocols-library-3.0.0-beta5-20140722.101428-756.jar \
  james-server-util-3.0.0-beta5-20140722.101359-761.jar \
  jutf7-1.0.0.jar \
  netty-3.3.1.Final.jar \
  protocols-api-1.6.4-20140722.113145-504.jar \
  protocols-imap-1.6.4-20140722.113327-357.jar \
  protocols-netty-1.6.4-20140722.113152-470.jar \
  slf4j-api-1.6.1.jar \
  slf4j-jcl-1.7.7.jar"


unpack() {
  local FILE="$PKG_GIT_HASH.zip"
  [ ! -d "$SOURCES/$PKG_NAME" ] && exit 1
  for u in $PKG_URL; do
    local f=`basename "$u"`
    [ ! -f "$SOURCES/$PKG_NAME/$f" ] && exit 1
  done
  local sourceDir=`cd $SOURCES/$PKG_NAME; pwd`
  (cd "$BUILD"
    rm -rf "$PKG_NAME-$PKG_VERSION" "$PKG_NAME-$PKG_GIT_HASH"
    unzip -o "$sourceDir/$FILE"
    if test $? -ne 0; then echo "Cannot extract from $sourceDir/$FILE"; exit 1; fi
    mv "$PKG_NAME-$PKG_GIT_HASH" "$PKG_NAME-$PKG_VERSION")
  (cd "$BUILD/$PKG_NAME-$PKG_VERSION/WebContent/WEB-INF/lib"
    unzip -oj "$sourceDir/apache-james-3.0-beta5-20140722-app.zip" `prepare_file_list_to_unzip $APACHE_JAMES_FILES_TO_EXTRACT`
    if test $? -ne 0; then exit 1; fi
    unzip -oj "$sourceDir/subethasmtp-3.1.7.zip" `prepare_file_list_to_unzip subethasmtp-3.1.7.jar`
    if test $? -ne 0; then exit 1; fi)
}

configure_target() {
  echo "Configuring $PKG_SHORTDESC"
  # do nothing
}

make_target() {
  test -n "$ANT_HOME" || ANT_HOME="`which ant | sed s%/bin/ant\$%% 2>/dev/null`"
  test -n "$JAVA_HOME" || JAVA_HOME="`which java | sed s%/bin/java\$%% 2>/dev/null`"
  rm -rf i2pbote-plugin.war
  PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH \
    I2P=`cd ../i2p.i2p; pwd` \
    $ANT_HOME/bin/ant --noconfig pluginwar 
}

makeinstall_target() {
  [ ! -f i2pbote-plugin.war ] && exit 1

  rm -rf "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote"
  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote/console/webapps"
  mkdir -p "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote/lib"
  
  cp plugin/plugin.config "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote"
  BUILD_DATE=`date -u +%s000`
  (echo ""; echo "version=${PKG_VERSION}-patched"; echo "date=$BUILD_DATE") >>"$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote/plugin.config"
  cp plugin/webapps.config "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote/console"
  cp i2pbote-plugin.war "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote/console/webapps/i2pbote.war"
  cp WebContent/WEB-INF/lib/* "$INSTALL/usr/lib/i2p/dist-plugins/plugins/i2pbote/lib"
}

unset -f prepare_file_list_to_unzip

prepare_file_list_to_unzip() {
  local result=
  for i in "$@"; do
    result="${result} *${i}"
  done
  echo "$result"
}
