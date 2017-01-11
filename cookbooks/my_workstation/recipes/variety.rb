#
# Cookbook Name:: my_workstation
# Recipe:: variety
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# UBUNTU ONLY!
return unless platform_family?('debian') 

#-----------------------------------------------------------------------------------------------------------------------
# Sugars
include_recipe 'chef-sugar::default'

#-----------------------------------------------------------------------------------------------------------------------
# Config

CURRENT_USER = ENV['SUDO_USER'].nil? ? ENV['USER'] : ENV['SUDO_USER']
log "CURRENT_USER is '#{CURRENT_USER}' because SUDO_USER is '#{ENV['SUDO_USER']}' & USER is '#{ENV['USER']}'."
node.default['authorization']['sudo']['users'] = %W(#{CURRENT_USER})

#-----------------------------------------------------------------------------------------------------------------------
# Manage General Packages

package 'variety' do
  action :install
end

#-----------------------------------------------------------------------------------------------------------------------
# General configuration changes

%W(
  #{ENV['HOME']}/.config/variety/
).each do |dir|
  directory dir do
    owner CURRENT_USER
    group CURRENT_USER
    recursive true
    action :create
  end
end

# "Variety" wallpaper changer util's config.
template "#{ENV['HOME']}/.config/variety/variety.conf" do
  source '.config/variety/variety.conf.erb'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0644'
  variables(custom_folder: "#{ENV['HOME']}/Pictures")
  not_if "test -e #{ENV['HOME']}/.config/variety/variety.conf"
end
