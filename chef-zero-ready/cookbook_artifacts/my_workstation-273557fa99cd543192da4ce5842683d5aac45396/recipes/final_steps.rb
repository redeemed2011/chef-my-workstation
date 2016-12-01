#
# Cookbook Name:: my_workstation
# Recipe:: final_steps
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

#-----------------------------------------------------------------------------------------------------------------------
# Sugars
include_recipe 'chef-sugar::default'

#-----------------------------------------------------------------------------------------------------------------------
# Config

CURRENT_USER = ENV['SUDO_USER'].nil? ? ENV['USER'] : ENV['SUDO_USER']
log "CURRENT_USER is '#{CURRENT_USER}' because SUDO_USER is '#{ENV['SUDO_USER']}' & USER is '#{ENV['USER']}'."
node.default['authorization']['sudo']['users'] = %W(#{CURRENT_USER})

#-----------------------------------------------------------------------------------------------------------------------
# General

# This is not idempotent.
bash 'fix perms on home' do
  # user CURRENT_USER
  code <<-EOH
    find #{ENV['HOME']} -user root -exec chown --no-dereference #{CURRENT_USER} {} +;
    find #{ENV['HOME']} -group root -exec chgrp --no-dereference #{CURRENT_USER} {} +;
  EOH
end
