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
# Packages

# Unity: stable unity desktop release.
# unity8-lxc: preview version of unity 8 destkop with Mir.
%w(
  lightdm
  compiz-plugins compizconfig-settings-manager
  unity
  unity-control-center
  unity-greeter
  unity-greeter-badges
  unity-settings-daemon
  unity-system-compositor
  unity-tweak-tool
  unity-webapps-qml
).each do |pkg|
  # unity8
  # unity8-desktop-session-mir
  package pkg do
    action :install
  end
end

%w(
  empathy
  evolution
  gdm
  gnome-shell
  gnome-session
  gnome-shell-extensions
  gnome-tweak-tool
  ubuntu-gnome-desktop
).each do |pkg|
  package pkg do
    action :purge
  end
end

log 'The latest, stable Unity desktop has been installed as well as the Unity 8 preview.'
