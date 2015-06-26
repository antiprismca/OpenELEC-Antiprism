#!/bin/bash

set -e

debug=

# trims the string
# Thanks http://stackoverflow.com/a/3352015
trim() {
    local var=$1
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

# $1 - rules file
# $2 - indent
# $3 - exclude list
function process() {
    local RULES_FILE=$1
    local ADD_INDENT=$2
    local EXCLUDE_LIST=$3
    
    (while IFS='' read -r line_sp || [[ -n $line_sp ]]; do 
        local indent=$(echo "$line_sp" | sed -e 's#^\([ \t]*\)[^ \t].*$#\1#')
        local line=$(echo "$line_sp" | sed -e 's#^[ \t]*\([^ \t].*\)$#\1#')
        if echo "$line" | grep -q '^%[\t ]*include[\t ]*='; then
            echo "$line" | sed 's#^%[\t ]*include[\t ]*=##' | tr ',' '\n' |\
                (while IFS='' read -r comp_sp || [[ -n $comp_sp ]]; do
                    local comp=$(echo "$comp_sp" | sed 's#^[ \t]##;s#[ \t]$##;')
                    local comp1=${comp%%/*}
                    local exclude=
                    if test ! "$comp1" == "$comp"; then
                        exclude=${comp#*/}
                        comp=$comp1
                    fi
                    if [[ -n $exclude ]]; then
                        echo "$exclude" | tr '/' '\n' |\
                        (while IFS='' read -r ex_sp || [[ -n $ex_sp ]]; do
                            local ex=$(trim "$ex_sp")
                            if ! grep -q "^[ \t]*\[${ex}\][ \t]*\$" "$RULES_FILE"; then
                                echo "*** ERROR: cannot find exclusion [$ex] in $RULES_FILE" >&2
                                exit 2
                            fi
                        done)
                    fi
                    echo "$EXCLUDE_LIST" | tr '/' '\n' |\
                    if test $(while IFS='' read -r ex_sp || [[ -n $ex_sp ]]; do
                        local ex=$(trim "$ex_sp")
                        if test "$ex" == "$comp"; then
                            echo -n 1
                            break
                        fi
                    done
                    echo 1) -eq 11; then
                        if [[ -n $debug ]]; then echo "# SKIP [$comp]"; fi
                    else
                        if grep -q "^[ \t]*\[${comp}\][ \t]*\$" "$RULES_FILE"; then
                            if [[ -n $debug ]]; then echo "# BEGIN [$comp]"; fi
                            sed -ne "/^[ \t]*\[${comp}\][ \t]*\$/,/^[ \t]*\[[-a-z0-9_]\+\][ \t]*\$/p" "$RULES_FILE" |\
                                sed -e '1d;$d;/^[ \t]*$/d' |\
                                process "$RULES_FILE" "$indent$ADD_INDENT" "${EXCLUDE_LIST}/${exclude}"
                            if [[ -n $debug ]]; then echo "# END [$comp]"; fi
                        else
                            echo "*** ERROR: cannot find [$comp] in $RULES_FILE" >&2
                            exit 2
                        fi
                    fi
                done)
        else
            echo "$indent$ADD_INDENT$line"
        fi
    done)
}

# main
# mkrules.sh rules_file <input.tmpl >output.profile
if [[ $# -ne 1 ]]; then
    echo -e "Usage:\n\t$0 rules_file <input.tmpl >output.profile" >&2
    exit 1
fi
process "$1" "" ""

