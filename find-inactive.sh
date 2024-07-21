#!/bin/bash

set -e -u

BILINGUAL=false

show_help () {
    cat >&2 <<EOF
USAGE: $0 [ dix ]

 -h, --help:      show this help

Look for entries in a bidix which may be inactive
due to other entries with more tags.

EOF
    exit 1
}

if [ $# -gt 0 ]; then
    while :; do
        case $1 in
            -h|-\?|--help)
                show_help
                ;;
            --)
                shift
                break
                ;;
            *)
                break
        esac
        shift
    done
fi

if [[ $# -eq 0 ]]; then
    echo "Dictionary not specified."
    exit 1
else
    DIX=$1
fi

dixtmp=$(mktemp -t gentestvoc.XXXXXXXXXXX)

find_inactive () {
    while IFS= read -r line; do
        direction=$(echo "$line" | cut -f1)
        output=$(echo "$line" | cut -f2,3,4)
        tags=$(echo "$line" | cut -f5)
        if [ "$direction" == "-->" ]; then
            search=$(echo '^'"$line" | cut -f1,2)
        else
            search=$(echo '\t'"$line" | cut -f3,4)
        fi
        if [ $(grep -c -e "$search" "$dixtmp") -gt 1 ]; then
            grep -e "$search" "$dixtmp" | while read -r entry ; do
               if [ $(echo "$entry" | cut -f5) -ne "$tags" ]; then
                   echo "$output"
                   break
               fi
            done
        fi
    done < "$dixtmp"
}

split_entries () {
    sed '/:[<>]:/b;s/\\:/§§§/g;s/:/:-:/g;s/§§§/\\:/g' \
    | awk -F':[<>\\-]:' '
             $0 ~ /:-:|:>:/ {print "-->\t" $1 "\t-->\t" $2}
             $0 ~ /:-:|:<:/ {print "<--\t" $1 "\t<--\t" $2}'
}

count_tags () {
    awk -F'\t' '
         $1 ~ /-->/ {print $0 "\t" gsub(/</,"",$2)}
         $1 ~ /<--/ {print $0 "\t" gsub(/</,"",$4)}'
}

lt-expand $DIX \
| split_entries \
| count_tags \
| grep -v "__REGEXP__" > "$dixtmp"

find_inactive

rm -f "$dixtmp"

exit 0
