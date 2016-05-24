#!/bin/bash

./export.sh

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

sudo -E chef-client -z -w #-l info

sudo -E chef-client -z -n 'gnome_workstation' -w #-l info

sudo -E chef-client -z -n 'unity_workstation' -w #-l info
