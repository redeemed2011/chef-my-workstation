#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop_personal
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
# Run Recipes

# Ubuntu specific.
include_recipe 'my_workstation::ubuntu_default_desktop_personal'

#-----------------------------------------------------------------------------------------------------------------------
# Resilio Sync (formerly BTSync)
# NOTE: Free edition cannot be used for businesses.

directory "#{ENV['HOME']}/resilio-sync/shares/" do
  owner CURRENT_USER
  group CURRENT_USER
  recursive true
  action :create
end

# # Attempt to download the latest resilio-sync.
# remote_file "#{ENV['HOME']}/resilio-sync/installer.tar.gz" do
#   owner CURRENT_USER
#   group CURRENT_USER
#   source 'https://download-cdn.resilio.com/stable/linux-x64/resilio-sync_x64.tar.gz'
#   # checksum 'sha256checksum'
# end

# # If the download fails, fall back to the included installer.
# cookbook_file "#{ENV['HOME']}/resilio-sync/installer.tar.gz" do
#   source 'files/resilio-sync_x64.tar.gz'
#   owner CURRENT_USER
#   group CURRENT_USER
#   mode '0644'
#   not_if "test -e '#{ENV['HOME']}/resilio-sync/installer.tar.gz'"
# end

# tarball "#{ENV['HOME']}/resilio-sync/installer.tar.gz" do
#   destination "#{ENV['HOME']}/resilio-sync/"
#   owner CURRENT_USER
#   group CURRENT_USER
#   # extract_list %W( * )
#   # umask 022 # Will be applied to perms in archive
#   action :extract
# end

cookbook_file '/usr/share/applications/resilio-sync.desktop' do
  source 'applications/resilio-sync.desktop'
  owner 'root'
  group 'root'
  mode '0644'
end

# directory "#{ENV['HOME']}/.config/autostart/" do
#   owner CURRENT_USER
#   group CURRENT_USER
#   recursive true
#   action :create
# end

# template "#{ENV['HOME']}/.config/autostart/resilio-sync.desktop" do
#   source '.config/autostart/resilio-sync.desktop.erb'
#   owner CURRENT_USER
#   group CURRENT_USER
#   mode '0664'
# end

#-----------------------------------------------------------------------------------------------------------------------
# Steam Hi-DPI Theme

%W(
  #{ENV['HOME']}/.steam/skins
  #{ENV['HOME']}/.steam/steam/skins
  #{ENV['HOME']}/.local/share/Steam/skins
).each do |dir|
  directory dir do
    owner CURRENT_USER
    group CURRENT_USER
    recursive true
    action :create
  end
end

git "#{ENV['HOME']}/.steam/skins/hidpi-skin" do
  repository 'https://github.com/MoriTanosuke/HiDPI-Steam-Skin.git'
  depth 1
  reference 'master'
  action :sync
end

link "#{ENV['HOME']}/.steam/steam/skins/hidpi-skin" do
  to "#{ENV['HOME']}/.steam/skins/hidpi-skin"
end

link "#{ENV['HOME']}/.local/share/Steam/skins/hidpi-skin" do
  to "#{ENV['HOME']}/.steam/skins/hidpi-skin"
end

# #-----------------------------------------------------------------------------------------------------------------------
# # General configuration changes

# bash 'disable touchpad when external mouse is present' do
#   code <<-EOH
#     gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled-on-external-mouse
#   EOH
#   not_if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host'
# end
