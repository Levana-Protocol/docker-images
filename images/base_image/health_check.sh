#!/bin/sh
set -eu

target="${1}" # localhost:3000/healthz or /status
now="$(date +%s)"
now_min="$(( now / 60 ))"

# Die when target is unreachable. Cannot use -O to save 500 http response.
curl --write-out "%{http_code}" -Ls "${target}" > "/tmp/${now_min}" || exit 1
http_code="$(tail -1 "/tmp/${now_min}")"
# This should not happen
[ "${http_code}" -eq 404 ] && exit 1

if [ "${target##*/}" = 'status' ]; then
    # further parsing /status
    grep 'Status: ERROR$' "/tmp/${now_min}" > "/tmp/${now_min}.error" || touch "/tmp/${now_min}.error"
    five="$(find /tmp/ -maxdepth 1 -mmin +5 -name '*.error' -exec stat -c '%Z %n' {} \; | sort -n | tail -1 | cut -d' ' -f2 || true)"
    if [ -n "${five}" ]; then
        same="$(diff "/tmp/${now_min}.error" "${five}" | grep -c '^ ' || true)" # same > 0 means there were same errors 5 mins ago
        [ "${same}" -gt 0 ] && exit 1
    fi
fi

# Main process must tee its output to /tmp/log
# bash -c 'mkdir -p /tmp/log && cd /tmp/log; main 2>&1 | tee >(split -b 10000 -)'
if [ -e /tmp/log/ ]; then
    cd /tmp/log/
    last_file="$(ls -t | head -1)"
    last_change="$(stat -c%Z "${last_file}")"
    for i in *; do
        [ "${i}" != "${last_file}" ] && rm -f "${i}"
    done
    [ "$(( now - last_change ))" -gt 120 ] && exit 1
fi
