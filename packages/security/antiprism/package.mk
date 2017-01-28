
PKG_NAME="antiprism"
PKG_VERSION=""
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://www.antiprism.ca"
PKG_URL=""

if [ "$TARGET_ARCH" = "arm" ]; then
  PKG_DEPENDS_TARGET="nasm:host LVM2 cryptsetup script.service.antiprism script.web.viewer fteproxy python-gnupg tor privoxy ecc-tools jq meek obfs4proxy v4l2grab hiawatha pyserial"
else
  PKG_DEPENDS_TARGET="rufus:host nasm:host rxvt-unicode gdk-pixbuf LVM2 cryptsetup script.service.antiprism truecrypt plugin.program.truecrypt plugin.program.linksbrowser fteproxy plugin.program.i2p python-gnupg tor i2p privoxy i2p.Seedless i2p.i2p-bote ecc-tools jq meek obfs4proxy v4l2grab hiawatha pyserial"
fi

PKG_PRIORITY="optional"
PKG_SECTION="virtual"
PKG_SHORTDESC="AntiPrism CA"
PKG_LONGDESC="AntiPrism CA"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

