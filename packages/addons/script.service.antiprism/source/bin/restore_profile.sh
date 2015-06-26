#!/bin/sh
set -o pipefail

ECC_DECRYPT="/usr/bin/ecc_decrypt"
TAR="/bin/tar"
DATA_DIRS="i2p .tor .gnupg"

# params:
# $1 - the mount point
# $2 - a backup file to restore

if test $# -ne 2; then echo "Usage: echo password | $0 mount_point backup_file" >&2; exit 1; fi

MOUNT_POINT=$1
BACKUP_FILE=$2

if test ! -f "$BACKUP_FILE"; then echo "File $BACKUP_FILE isn't accessible!" >&2; exit 1; fi
if test ! -d "$MOUNT_POINT"; then echo "$MOUNT_POINT is not a directory!" >&2; exit 1; fi

for dir in $DATA_DIRS; do
  if test -e "$MOUNT_POINT/$dir"; then
    if test "$dir" == "i2p"; then
      rm -rf "$MOUNT_POINT/$dir"
    else 
      echo "Data dir $MOUNT_POINT/$dir exists!" >&2
      exit 1
    fi
  fi
done

$ECC_DECRYPT "$BACKUP_FILE" | (cd "$MOUNT_POINT"; $TAR xzf -)
if test $? -ne 0; then 
  exit 3 
fi

# re-create things that we didn't backup
mkdir -p "$MOUNT_POINT/i2p/i2psnark"
mkdir -p "$MOUNT_POINT/i2p/logs"
echo >"$MOUNT_POINT/i2p/wrapper.log"

rm -f "$MOUNT_POINT/.tor/lock"
exit 0

