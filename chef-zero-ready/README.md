# Exported Chef Repository for Policy 'chef-my_workstation'

Policy revision: 5f05c7a2a3f8c0b3afba39270ad60157b3a1eb149ce4c0645673e9f55a87b5a4

This directory contains all the cookbooks and configuration necessary for Chef
to converge a system using this exported policy. To converge a system with the
exported policy, use a privileged account to run `chef-client -z` from the
directory containing the exported policy.

## Contents:

### Policyfile.lock.json

A copy of the exported policy, used by the `chef push-archive` command.

### .chef/config.rb

A configuration file for Chef Client. This file configures Chef Client to use
the correct `policy_name` and `policy_group` for this exported repository. Chef
Client will use this configuration automatically if you've set your working
directory properly.

### cookbook_artifacts/

All of the cookbooks required by the policy will be stored in this directory.

### policies/

A different copy of the exported policy, used by the `chef-client` command.

### policy_groups/

Policy groups are used by Chef Server to manage multiple revisions of the same
policy. However, exported policies contain only a single policy revision, so
this policy group name is hardcoded to "local" and should not be changed.

