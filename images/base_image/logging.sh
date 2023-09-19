#!/bin/bash
set -eu -o pipefail

cmd=( "${@}" )

mkdir -p /tmp/log
cd /tmp/log
${cmd[@]} 2>&1 | tee >(split -l 100000 -)
