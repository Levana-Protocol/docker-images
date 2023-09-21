#!/bin/sh
set -eu

target="${1}" # localhost:3000/healthz or /status
now="$(date +%s)"
now_min="$(( now / 60 ))"

# Die when target is unreachable. Cannot use -O to save 500 http response.
curl --write-out "\n%{http_code}" -Ls "${target}" > "/tmp/${now_min}" || exit 1
http_code="$(tail -1 "/tmp/${now_min}")"
# This should not happen
if [ "${http_code}" -eq 404 ]; then
    exit 1
fi

# further parsing /status
if [ "${target##*/}" = 'status' ]; then
    # when grep gets no result, the error file is not created. Hence touch to keep logic going on.
    grep 'Status: ERROR$' "/tmp/${now_min}" > "/tmp/${now_min}.error" || touch "/tmp/${now_min}.error"
    five="$(find /tmp/ -maxdepth 1 -mmin +5 -name '*.error' -exec stat -c '%Z %n' {} \; | sort -n | tail -1 | cut -d' ' -f2 || true)"
    if [ -n "${five}" ]; then
        same="$(diff "/tmp/${now_min}.error" "${five}" | grep -c '^ ' || true)" # same > 0 means there were same errors 5 mins ago
        if [ "${same}" -gt 0 ]; then
            exit 1
        fi
    fi
fi

# Main process must tee its output to /tmp/log via logging.sh
if [ -e /tmp/log/ ]; then
    cd /tmp/log/
    last_file="$(ls -t | head -1)"
    last_change="$(stat -c%Z "${last_file}")"
    for i in *; do
        if [ "${i}" != "${last_file}" ]; then
            rm -f "${i}"
        fi
    done
    if [ "$(( now - last_change ))" -gt 120 ]; then
        exit 1
    fi
fi
