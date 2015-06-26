#!/bin/sh
set -o pipefail

ECC_ENCRYPT="/usr/bin/ecc_encrypt"
TAR="/bin/tar"
KEY_LOCAL_PATH=".keys/key_file.dat"
DATA_DIRS="\
    i2p/Seedless.config \
    i2p/SeedlessVersion \
    i2p/Seedlessdb \
    i2p/addressbook \
    i2p/blocklist.txt \
    i2p/clients.config \
    i2p/docs \
    i2p/eepsite \
    i2p/eventlog.txt \
    i2p/hosts.txt \
    i2p/hostsdb.blockfile \
    i2p/i2pbote \
    i2p/i2psnark.config \
    i2p/i2ptunnel-keyBackup \
    i2p/i2ptunnel.config \
    i2p/keyBackup \
    i2p/netDb \
    i2p/peerProfiles \
    i2p/plugins \
    i2p/quickseeds.txt \
    i2p/router.config \
    i2p/router.info \
    i2p/router.keys \
    i2p/router.keys.dat \
    i2p/router.ping \
    i2p/rrd \
    i2p/systray.config \
    i2p/webapps.config \
    .tor \
    .gnupg"
# Do not backup following:
#    i2p/i2psnark
#    i2p/logs
#    i2p/wrapper.log

# params:
# $1 - the mount point
# $2 - a backup file to create

if test $# -ne 2; then echo "Usage: $0 mount_point target_file" >&2; exit 1; fi

MOUNT_POINT=$1
BACKUP_FILE=$2
KEY_FILE="$MOUNT_POINT/$KEY_LOCAL_PATH"

if test -e "$BACKUP_FILE"; then echo "File $BACKUP_FILE already exists!" >&2; exit 1; fi
if test ! -f "$KEY_FILE"; then echo "Key file doesn't exist!" >&2; exit 1; fi
if test ! -d "$MOUNT_POINT"; then echo "$MOUNT_POINT is not a directory!" >&2; exit 1; fi

TO_BACKUP=
for dir in $DATA_DIRS; do
  if test -e "$MOUNT_POINT/$dir"; then TO_BACKUP="${TO_BACKUP}$dir\n"; fi
done

if test -z "$TO_BACKUP"; then echo "Nothing to backup!" >&2; exit 2; fi

(cd "$MOUNT_POINT"; echo -en "$TO_BACKUP" | $TAR czf - -T -) | $ECC_ENCRYPT "$KEY_FILE" "$BACKUP_FILE"
if test $? -ne 0; then
  rm -f "$BACKUP_FILE" >/dev/null 2>&1
  exit 3 
fi
exit 0

