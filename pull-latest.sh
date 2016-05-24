#!/bin/bash

CURRENT_USER="${SUDO_USER}"
[ -z "${CURRENT_USER}" ] && CURRENT_USER="${USER}"

set +e
which git
RETVAL=$?
set -e
if [ ${RETVAL} -ne 0 ]; then
  sudo apt-get install -y git
fi

sudo chown -R ${CURRENT_USER}: .

git reset --hard HEAD

git pull
