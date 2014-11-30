#!/bin/bash

VERIFY_LIST="verify_md5.lst"

if ! [ -f "$VERIFY_LIST" ]; then
  echo -n "Building $VERIFY_LIST..."
  echo "# Created: `date`" > "$VERIFY_LIST"
  echo "# Confirm the md5 are correct!" >> "$VERIFY_LIST"
  echo "#" >> "$VERIFY_LIST"
  if find sources/ -name *.md5 | while read f; do cat "$f" >> "$VERIFY_LIST"; done; then
    echo "`md5sum \"$VERIFY_LIST\"`" > "$VERIFY_LIST.md5"
    chmod a-w "$VERIFY_LIST"
    chmod a-w "$VERIFY_LIST.md5"
    echo "OK"
  fi
  exit $?
fi

if [ -f "$VERIFY_LIST.md5" ]; then
  echo -n "Verifying $VERIFY_LIST..."
  MD5="`md5sum \"$VERIFY_LIST\"`"
  if [ "$MD5" != "`cat \"$VERIFY_LIST.md5\"`" ]; then
    echo "FAILED!"
    exit 1
  fi
  echo "$MD5" > "$VERIFY_LIST.md5"
  chmod a-w "$VERIFY_LIST.md5" || exit 2 
  echo "OK"
fi

echo "Verifying packages against $VERIFY_LIST..."

grep "^[^#]" "$VERIFY_LIST" | while read md5 f; do \
  if ! [ -f "$f" ]; then \
    echo "File $f does not exist"; \
  else \
    echo -n "$f..."; \
    MD5="`md5sum \"$f\" | cut -f 1 -d \" \"`"; \
    if [ "$md5" != "$MD5" ]; then \
      echo "FAILED"; \
      exit 3; \
    fi; \
    echo "OK"; \
  fi; \
done

echo -n "Updating $VERIFY_LIST..."
rm -f "$VERIFY_LIST.tmp" 2>/dev/null
find sources/ -name *.md5 | while read f; do \
  if ! grep "$f" "$VERIFY_LIST"; then \
    cat "$f" >> "$VERIFY_LIST.tmp"; \
  fi; \
done

if [ -f "$VERIFY_LIST.tmp" ]; then
  NEW=`grep -c "" "$VERIFY_LIST.tmp"`
  if chmod u+w "$VERIFY_LIST" && chmod u+w "$VERIFY_LIST.md5"; then
    echo "#" >> "$VERIFY_LIST"
    echo "# Updated: `date`" >> "$VERIFY_LIST"
    echo "#" >> "$VERIFY_LIST"
    cat "$VERIFY_LIST.tmp" >> "$VERIFY_LIST"
  else
    echo " FAILED"
    exit 4
  fi
  rm -f "$VERIFY_LIST.tmp"
  echo "`md5sum \"$VERIFY_LIST\"`" > "$VERIFY_LIST.md5" 
  if ! chmod a-w "$VERIFY_LIST.md5" || ! chmod a-w "$VERIFY_LIST.md5"; then
    echo "Failed to set read-only flag"
  fi
  echo "added $NEW packages, please verify"
else
  echo "up to date"
fi
 
