#
# Cookbook Name:: my_workstation
# Recipe:: gnome_desktop
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
# Add Repositories

apt_repository 'gnome3' do
  uri 'ppa:gnome3-team/gnome3'
  distribution node.deep_fetch(:lsb, :codename)
  components ['main']
end

apt_repository 'gnome3-staging' do
  uri 'ppa:gnome3-team/gnome3-staging'
  distribution node.deep_fetch(:lsb, :codename)
  components ['main']
end

# Have not used this ppa in many years. This chef code may be wrong (space in name).
# apt_repository 'gnome ricotz/testing' do
#   uri 'ppa:ricotz/testing'
#   distribution node.deep_fetch(:lsb, :codename)
#   components ['main']
# end

#-----------------------------------------------------------------------------------------------------------------------
# Packages

%w(
  gdm
  gnome-shell
  gnome-session
  gnome-shell-extensions
  gnome-tweak-tool
  ubuntu-gnome-desktop
).each do |pkg|
  package pkg do
    action :install
  end
end

# Never wanted.
%w(
  evolution
  empathy
  gnome-books
  gnome-contacts
  gnome-documents
  gnome-maps
  gnome-music
  gnome-photos
).each do |pkg|
  package pkg do
    action :purge
    # notifies :restart, 'service[gdm]', :delayed
  end
end

%w(
  lightdm
  compiz-plugins compizconfig-settings-manager
  unity
  unity-greeter
  unity-greeter-badges
  unity-reboot
  unity-scope-loader
  unity-system-compositor
  unity-system-compositor-spinner
  unity-system-compositor.sleep
  unity-tweak-tool
  unity-webapps-desktop-file
  unity-webapps-qml-launcher
  unity-webapps-runner
).each do |pkg|
  # unity-settings-daemon
  # unity-control-center
  package pkg do
    action :purge
    # notifies :restart, 'service[gdm]', :delayed
  end
end

service 'gdm' do
  supports status: true, restart: true, reload: true
  action :enable
  notifies :run, 'execute[reconfigure_gdm]'
end

# Ensure GDM becomes the default.
execute 'reconfigure_gdm' do
  command 'dpkg-reconfigure -f noninteractive gdm'
  action :nothing
end

# link '/etc/systemd/system/display-manager.service' do
#   to '/lib/systemd/system/gdm.service'
#   link_type :symbolic
#   owner 'root'
#   group 'root'
# end
