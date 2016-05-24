#!/bin/bash

set -e

CURRENT_USER="${SUDO_USER}"
[ -z "${CURRENT_USER}" ] && CURRENT_USER="${USER}"

# Has chef-client been installed?
set +e
which chef-client
RETVAL=$?
set -e
if [ ${RETVAL} -ne 0 ]; then
  # Install chef-client using Omnibus.
  wget -O- https://www.opscode.com/chef/install.sh | sudo bash -s
fi

cd chef-zero-ready

sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" .

sudo -E chef-client -z #-l info
