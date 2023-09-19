#!/bin/sh
set -eu

target="${1}"
now="$(date +%s)"
now_min="$(( now / 60 ))"

wget -S -O "/tmp/${now_min}" "${target}" || exit 1

if [ "${target##*/}" = 'status' ]; then
    # further parsing /status
    grep 'Status: ERROR' "/tmp/${now_min}" > "/tmp/${now_min}.error"
    five="$(( now_min - 5 ))"
    same="$(comm -12 "/tmp/${now_min}.error" "/tmp/${five}.error" | wc -l)" # same > 0 means there were same errors 5 mins ago
    [ "${same}" -gt 0 ] && exit 1
fi
