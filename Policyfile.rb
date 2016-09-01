# Policyfile.rb - Describe how you want Chef to build your system.
#
# For more information on the Policyfile feature, visit
# https://github.com/opscode/chef-dk/blob/master/POLICYFILE_README.md

# A name that describes what the system you're building with Chef does.
name 'chef-my_workstation'

# Where to find external cookbooks:
default_source :supermarket

# Specify a named run-list to be used as an alternative to the override run-list. This setting should be used carefully
# and for specific use cases, like running a small set of recipes to quickly converge configuration for a single
# application on a host or for one-time setup tasks.
named_run_list 'default_workstation', 'my_workstation::default', 'my_workstation::default_desktop', 'my_workstation::final_steps'
named_run_list 'default_personal_workstation', 'my_workstation::default', 'my_workstation::default_desktop', 'my_workstation::default_desktop_personal', 'my_workstation::final_steps'
named_run_list 'gnome_workstation', 'my_workstation::gnome_desktop', 'my_workstation::default', 'my_workstation::default_desktop', 'my_workstation::final_steps'
named_run_list 'unity_workstation', 'my_workstation::unity_desktop', 'my_workstation::default', 'my_workstation::default_desktop', 'my_workstation::final_steps'
named_run_list 'test_code', 'my_workstation::test_code'

# run_list: chef-client will run these recipes in the order specified.
run_list 'my_workstation::default', 'my_workstation::final_steps'

# Specify a custom source for a single cookbook:
cookbook 'my_workstation', path: './cookbooks/my_workstation'
cookbook 'tarball', github: 'ooyala/tarball-chef-cookbook', branch: 'master'
