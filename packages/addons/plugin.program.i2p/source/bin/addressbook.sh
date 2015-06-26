#!/bin/sh
set -o pipefail

############################################################## helper fuctions ############################################################
checkPassword() {
    local PASSWD=
    if test $# -gt 0; then
        PASSWD="$1"; shift
    fi
    if (test -z "$PASSWD") && (test -f "$PASSWORD_FILE"); then
        echo "I2p-bote password is needed">&2
        return 2
    fi
    if (test ! -z "$PASSWD") && (test ! -f "$PASSWORD_FILE"); then
        echo "I2p-bote password is NOT needed">&2
        return 2
    fi
    if test ! -f "$PASSWORD_FILE"; then return 0; fi
    local decrypted=`echo "$PASSWD" | ecc_safedecrypt "$PASSWORD_FILE"`
    if test "$decrypted" == "$PASSWORD_ENCRYPTED_PHRASE"; then 
        return 0
    else 
        echo "I2p-bote password is wrong">&2
        return 1
    fi
}

getIdentities() {
    local PASSWD=
    if test $# -gt 0; then
        PASSWD="$1"; shift
    fi
    
    if (test -f "$IDENTITIES_FILE") && (test -r "$IDENTITIES_FILE"); then
        ((echo -n '{"ids":'
        echo "$PASSWD" | ecc_safedecrypt "$IDENTITIES_FILE" |\
        jq -R -s -c '[. | split("\n") | .[] | select(startswith("identity")) | split("=") |
                   (.[0] | split(".")) + [.[1]] | .[0] = (.[0] | ltrimstr("identity") | tonumber) |
                   select(.[1] == "key" or .[1] == "publicName")] |
                   sort_by(.[0]) as $sparse |
                   [([$sparse | .[] | .[0]] | unique | .[] | . as $u | {num:$u} |
                       .key = ($sparse | .[] | select($u == .[0] and .[1] == "key") | .[2]) |
                       .name = ($sparse | .[] | select($u == .[0] and .[1] == "publicName") | .[2]))
                   ]
        ')
        echo -n ',"keyLengths":'
        jq -c -n '[
            {public:86,  total:172},
            {public:174, total:348},
            {public:512, total:880},
            {public:2079,total:97813}
        ]' ; echo -n '}') |\
        jq -c '[
            (.keyLengths | .[]) as $keyLength | 
            .ids | .[] | select((.key | length) == $keyLength.total) | 
            .destination = .key[0:$keyLength.public] |
            {name: .name, destination:.destination, type:"identity"}
        ]'
    else
        echo -n '[]'
    fi
}

getAddressBook() {
    local PASSWD=
    if test $# -gt 0; then
        PASSWD="$1"; shift
    fi
    if (test -f "$ADDRESS_BOOK_FILE") && (test -r "$ADDRESS_BOOK_FILE"); then
        echo "$PASSWD" | ecc_safedecrypt "$ADDRESS_BOOK_FILE"  | \
        jq -R -s -c '[. | split("\n") | .[] | select(startswith("contact")) | split("=") |
                   (.[0] | split(".")) + [.[1]] | .[0] = (.[0] | ltrimstr("contact") | tonumber)] |
                   sort_by(.[0]) as $sparse |
                   [([$sparse | .[] | .[0]] | unique | .[] | . as $u | {num:$u} |
                       .destination = ($sparse | .[] | select($u == .[0] and .[1] == "destination") | .[2]) |
                       .name = ($sparse | .[] | select($u == .[0] and .[1] == "name") | .[2]) |
                       .picture = ($sparse | .[] | select($u == .[0] and .[1] == "picture") | .[2]) |
                       .text = ($sparse | .[] | select($u == .[0] and .[1] == "text") | .[2]) |
                       .type = "addressbook" | del(.num))
                   ]
        '
    else
        echo -n '[]'
    fi

}

readAddressBook() {
    local PASSWD=
    if test $# -gt 0; then
        PASSWD="$1"; shift
    fi
    
    (echo -n '"i2pbote":';
        ((getAddressBook "$PASSWD"; getIdentities "$PASSWD") |\
        jq -s -c '. | add'))

}

readAddressBookForImport() {
    local PASSWD=
    if test $# -gt 0; then
        PASSWD="$1"; shift
    fi
    
    (echo -n '"i2pboteABOnly":'; getAddressBook "$PASSWD")

}

readGPG() {
    (echo -n '"gnupg":'
    GNUPGHOME="$MOUNT_POINT/.gnupg" gpg --list-keys --with-colons |\
    sed -ne '/^pub:/p' |\
    awk -F':' '
        BEGIN {
            printf "[";
            first = 1;
        }
        {
            if (first == 0) {
                printf ",";
            } else {
                first = 0;
            }
            printf "{\"id\":\"%s\",\"name\":\"%s\"}", $5, $10;

        }
        END {
            printf "]";
        }
    '
    if test $? -ne 0; then echo -n ''; fi)
}

############################################################## main entry point ############################################################

if test $# -ge 1; then
  command=$1; shift
fi

if test $# -ge 1; then
  MOUNT_POINT=$1; shift
fi

if test -z "$command"; then
  echo "Command is required" >&2
  echo "Usage: `basename $0` command mount-point [args]" >&2
  exit 2
fi
if (test -z "$MOUNT_POINT") || (test ! -d "$MOUNT_POINT"); then
  echo "Mount point is required" >&2
  echo "Usage: `basename $0` command mount-point [args]" >&2
  exit 2
fi
MOUNT_POINT=`cd "$MOUNT_POINT"; pwd`

IDENTITIES_FILE="$MOUNT_POINT/i2p/i2pbote/identities"
ADDRESS_BOOK_FILE="$MOUNT_POINT/i2p/i2pbote/addressBook"
ADDRESS_BOOK_FILE_TEMP="$ADDRESS_BOOK_FILE-temp"
ADDRESS_BOOK_FILE_BAK="$ADDRESS_BOOK_FILE-bak"
PASSWORD_FILE="$MOUNT_POINT/i2p/i2pbote/password"
PASSWORD_ENCRYPTED_PHRASE="If this is the decrypted text, the password was correct."

TEMP_FILE="/tmp/addressbook.$$.tmp"
TEMP_FILE1="/tmp/addressbook.$$-1.tmp"

############################################################## command: list ###############################################################
if test "$command" == "list"; then

  inp=`cat - | jq -c 'select((. | type | . == "object") and 
                                   (.i2pbotePasswd | type | . == "string")) |
                           {i2pbotePasswd:.i2pbotePasswd}'`
  if (test $? -ne 0) || (test -z "$inp"); then echo "No or bad input" >&2; exit 2; fi
  
  i2pbotePasswd=`echo -n "$inp" | jq -c -r '.i2pbotePasswd'`
  if (test $? -ne 0) || (! checkPassword "$i2pbotePasswd"); then echo "Bad i2pbotePasswd" >&2; exit 2; fi

  (echo -n '{'
  readAddressBook "$i2pbotePasswd"
  echo -n ','
  readGPG
  echo -n '}') | jq -c '{i2pbote:[(.i2pbote|.[]|.id=(.destination + .type|sha1)|del(.destination)|del(.text)|del(.picture))],gnupg:.gnupg}'

############################################################## command: import #############################################################
elif  test "$command" == "import"; then
  if test $# -ge 1; then
    infile=$1; shift
  else
    echo "No input file" >&2; exit 2;
  fi
  
  if ! test -f "$infile"; then
    echo "Input file does not exist" >&2; exit 2;
  fi
  
  rm -f "$TEMP_FILE"
  rm -f "$TEMP_FILE1"
  
  inp=`cat - | jq -c 'select((. | type | . == "object") and 
                                   (.i2pbotePasswd | type | . == "string") and
                                   (.gnupgPasswd | type | . == "string")) |
                           {i2pbotePasswd:.i2pbotePasswd,gnupgPasswd:.gnupgPasswd}'`
  if (test $? -ne 0) || (test -z "$inp"); then echo "No or bad input" >&2; exit 2; fi
  
  i2pbotePasswd=`echo -n "$inp" | jq -c -r '.i2pbotePasswd'`
  if (test $? -ne 0) || (! checkPassword "$i2pbotePasswd"); then echo "Bad i2pbotePasswd" >&2; exit 2; fi
  
  gnupgPasswd=`echo -n "$inp" | jq -c -r '.gnupgPasswd'`
  if test $? -ne 0; then echo "Bad gnupgPasswd" >&2; exit 2; fi
  
  if test -z "$gnupgPasswd"; then
    GNUPGHOME="$MOUNT_POINT/.gnupg" gpg -q --no-tty --batch --output "$TEMP_FILE" --decrypt "$infile"
  else
    echo -n "$gnupgPasswd" | GNUPGHOME="$MOUNT_POINT/.gnupg" gpg -q --no-tty --batch --passphrase-fd 0 --output "$TEMP_FILE" --decrypt "$infile"
  fi
  if test $? -ne 0; then rm -f "$TEMP_FILE"; echo "Cannot decrypt">&2; exit 2; fi
  
  rm -f "$ADDRESS_BOOK_FILE_TEMP"
  if test -e "$ADDRESS_BOOK_FILE_TEMP"; then rm -f "$TEMP_FILE"; echo "Cannot remove temp file">&2; exit 2; fi
  
  importedCount=`(echo -n '{'; readAddressBook "$i2pbotePasswd"; echo -n ',"import":'; cat "$TEMP_FILE"; echo -n '}') |\
    jq -c -r '[(.i2pbote[] | .destination)] as $existing | [(.import[] | select([.destination == ($existing[] | .)] | any | not))] | length'`
  ignoredCount=`(echo -n '{'; readAddressBook "$i2pbotePasswd"; echo -n ',"import":'; cat "$TEMP_FILE"; echo -n '}') |\
    jq -c -r '[(.i2pbote[] | .destination)] as $existing | [(.import[] | select([.destination == ($existing[] | .)] | any))] | length'`
  (echo -n '{'; readAddressBook "$i2pbotePasswd"; echo -n ','; readAddressBookForImport "$i2pbotePasswd"; echo -n ',"import":'; cat "$TEMP_FILE"; echo -n '}') |\
  jq -c -r '[(.i2pbote[] | .destination)] as $existing | [(.import[] | select([.destination == ($existing[] | .)] | any | not))] + .i2pboteABOnly |
         range(0; . | length) as $n | .[$n] | 
         "contact" + ($n|tostring) + ".name=" + .name + "\n" + 
         "contact" + ($n|tostring) + ".destination=" + .destination + "\n" +
         "contact" + ($n|tostring) + ".picture=" + .picture + "\n" +
         "contact" + ($n|tostring) + ".text=" + .text' >"$TEMP_FILE1"
  if test ! -f "$TEMP_FILE1"; then rm -f "$TEMP_FILE"; echo "Cannot create temp file">&2; exit 2; fi
  
  if test -f "$ADDRESS_BOOK_FILE"; then 
    cp "$ADDRESS_BOOK_FILE" "$ADDRESS_BOOK_FILE_BAK"
    if (test $? -ne 0) || (test ! -f "$ADDRESS_BOOK_FILE_BAK"); then rm -f "$TEMP_FILE"; echo "Cannot create backup file">&2; exit 2; fi
  fi
  
  echo "$i2pbotePasswd" | ecc_safeencrypt "$TEMP_FILE1" "$ADDRESS_BOOK_FILE_TEMP"
  if test $? -ne 0; then 
    rm -f "$ADDRESS_BOOK_FILE_TEMP"
    rm -f "$TEMP_FILE"
    rm -f "$TEMP_FILE1"
    echo "Cannot encrypt addressbook file">&2
    exit 2
  fi
  cp "$ADDRESS_BOOK_FILE_TEMP" "$ADDRESS_BOOK_FILE"
  if test $? -ne 0; then 
    rm -f "$ADDRESS_BOOK_FILE_TEMP"
    rm -f "$TEMP_FILE"
    rm -f "$TEMP_FILE1"
    if test -f "$ADDRESS_BOOK_FILE_BAK"; then cp "$ADDRESS_BOOK_FILE_BAK" "$ADDRESS_BOOK_FILE"; else rm -f "$ADDRESS_BOOK_FILE_BAK"; fi
    echo "Cannot replace addressbook file">&2
    exit 2
  fi
  rm -f "$ADDRESS_BOOK_FILE_TEMP"
  jq -c -n --arg importedCount "$importedCount" --arg ignoredCount "$ignoredCount" \
    '{imported:($importedCount|tonumber),ignored:($ignoredCount|tonumber),errors:0}'
  if test $? -ne 0; then 
    rm -f "$TEMP_FILE"
    rm -f "$TEMP_FILE1"
    if test -f "$ADDRESS_BOOK_FILE_BAK"; then cp "$ADDRESS_BOOK_FILE_BAK" "$ADDRESS_BOOK_FILE"; else rm -f "$ADDRESS_BOOK_FILE_BAK"; fi
    echo "Cannot create report">&2
    exit 2
  fi
  rm -f "$TEMP_FILE"
  rm -f "$TEMP_FILE1"
  
############################################################## command: export #############################################################
elif  test "$command" == "export"; then
  if test $# -ge 1; then
    outfile=$1; shift
  else
    echo "No output file" >&2
    exit 2
  fi
  if test -e "$outfile"; then
    echo "Output file already exists" >&2
    exit 2
  fi
  
  inp=`cat - | jq -c 'select((. | type | . == "object") and 
                                   (.i2pbotePasswd // "" | type | . == "string") and
                                   (.gnupgPasswd // "" | type | . == "string") and
                                   ((.recipient | type | . == "string") or
                                   (.recipients | type | . == "array")) and
                                   (.identities | type | . == "array")) |
                           .recipients = ((.recipients // []) + (if has("recipient") then [.recipient] else [] end)) |
                           {i2pbotePasswd:(.i2pbotePasswd // ""),
                            gnupgPasswd:  (.gnupgPasswd // ""),
                            identities:    .identities,
                            recipients:   .recipients}'`
  if (test $? -ne 0) || (test -z "$inp"); then echo "No or bad input" >&2; exit 2; fi
  
  i2pbotePasswd=`echo -n "$inp" | jq -c -r '.i2pbotePasswd'`
  if (test $? -ne 0) || (! checkPassword "$i2pbotePasswd"); then echo "Bad i2pbotePasswd" >&2; exit 2; fi
  
  gnupgPasswd=`echo -n "$inp" | jq -c -r '.gnupgPasswd'`
  if test $? -ne 0; then echo "Bad gnupgPasswd" >&2; exit 2; fi
  
  identities=`echo -n "$inp" | jq -c '.identities'`
  if (test $? -ne 0) || (test -z "$identities"); then echo "Bad list of identities" >&2; exit 2; fi
  identitiesCount=`echo $identities | jq -c '[(.[])]|length'`
  if (test $? -ne 0) || (test -z "$identitiesCount") || (test ! $identitiesCount -gt 0); then echo "Empty list of identities" >&2; exit 2; fi
  
  recipients=`echo -n "$inp" | jq -c -r '.recipients | .[]'`
  if test -z "$recipients"; then echo "Bad recipient list" >&2; exit 2; fi
  
  toExclude=`(echo -n '{'; readAddressBook "$i2pbotePasswd"; echo -n ',"identities":'; echo -n "$identities"; echo -n '}') |\
      jq -c '[
          (.identities | .[] | .) as $id1 |
          (.identities | .[] | .) as $id2 |
          (.i2pbote | .[] | .) as $one |
          .i2pbote | (.[] | 
              select(($one.destination + $one.type | sha1) == $id1 and 
                     (.destination + .type | sha1) == $id2 and 
                     .destination == $one.destination and 
                     .type == "addressbook" and 
                     $one.type == "identity")) |
          .destination + .type | sha1
      ]'`
  toSaveCount=`(echo -n '{'
    echo -n '"exclude":'; echo -n "$toExclude,"
    echo -n '"identities":'; echo -n "$identities,"
    readAddressBook "$i2pbotePasswd"
    echo -n '}') |\
      jq -c '[
          (.exclude as $exclude |
          (.identities | .[] | .) as $id |
          .i2pbote |(.[]|select((.destination + .type|sha1) as $destId | ($destId == $id and ($exclude | contains([$destId]) | not)))))
      ] | length'`
      
  recipientsCmd=
  for rcp in $recipients; do
      recipientsCmd="$recipientsCmd --recipient $rcp"
  done

  if test -z "$gnupgPasswd"; then
    (echo -n '{'
    echo -n '"exclude":'; echo -n "$toExclude,"
    echo -n '"identities":'; echo -n "$identities,"
    readAddressBook "$i2pbotePasswd"
    echo -n '}') |\
      jq -c '[
          (.exclude as $exclude |
          (.identities | .[] | .) as $id |
          .i2pbote |(.[]|select((.destination + .type|sha1) as $destId | ($destId == $id and ($exclude | contains([$destId]) | not))) | 
          .text = "" | .picture = ""))
      ]' |\
      GNUPGHOME="$MOUNT_POINT/.gnupg" gpg --encrypt $recipientsCmd --batch --always-trust -o "$outfile"
    if (test $? -ne 0) || (test ! -f "$outfile"); then rm -f "$outfile"; echo "Cannot encrypt" >&2; exit 2; fi
  else
    (echo -n '{'
    echo -n '"exclude":'; echo -n "$toExclude,"
    echo -n '"identities":'; echo -n "$identities,"
    readAddressBook "$i2pbotePasswd"
    echo -n '}') |\
      jq -c '[
          (.exclude as $exclude |
          (.identities | .[] | .) as $id |
          .i2pbote |(.[]|select((.destination + .type|sha1) as $destId | ($destId == $id and ($exclude | contains([$destId]) | not))) |
          .text = "" | .picture = ""))
      ]' |\
      GNUPGHOME="$MOUNT_POINT/.gnupg" gpg --passphrase-fd 3 --encrypt --sign $recipientsCmd --batch --always-trust -o "$outfile" 3<<_END_OF_PASSWORD_
$gnupgPasswd
_END_OF_PASSWORD_
    if (test $? -ne 0) || (test ! -f "$outfile"); then rm -f "$outfile"; echo "Cannot encrypt and sign" >&2; exit 2; fi
  fi  
  
  echo -n "$toExclude" | jq -c --arg exportedCount "$toSaveCount" \
    '{exported:($exportedCount|tonumber),ignored:(. | length)}'

  if test $? -ne 0; then rm -f "$outfile"; echo "Cannot create a report" >&2; exit 2; fi
  
############################################################## command: other #############################################################
else
  echo "Invalid command. Must be one of: list, import, export" >&2
  exit 2
fi
exit 0
