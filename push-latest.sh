#!/bin/bash

set -e

CURRENT_USER="${SUDO_USER}"
[ -z "${CURRENT_USER}" ] && CURRENT_USER="${USER}"

sudo chown -R ${CURRENT_USER}: .

./export.sh

git add -A .

git commit -a

git push
