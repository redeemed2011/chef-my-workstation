#!/bin/bash

set -x

CURRENT_USER="${SUDO_USER}"
[ -z "${CURRENT_USER}" ] && CURRENT_USER="${USER}"

# Has ChefDK been installed?
set +e
which chef
RETVAL=$?
set -e
if [ ${RETVAL} -ne 0 ]; then
  # Install ChefDK using Omnibus.
  wget -O- https://www.opscode.com/chef/install.sh | sudo bash -s -- -P chefdk
fi



# Build the policy file & it's dependencies.
chef update

# "chef export" may error due to permissions.
[ -d chef-zero-ready ] && sudo chown -R ${CURRENT_USER}: chef-zero-ready

# Export the policy to something that chef zero knows how to run.
chef export chef-zero-ready -f
