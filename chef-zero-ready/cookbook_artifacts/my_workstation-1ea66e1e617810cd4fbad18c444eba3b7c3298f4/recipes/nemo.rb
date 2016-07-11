#
# Cookbook Name:: my_workstation
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

#-----------------------------------------------------------------------------------------------------------------------
# Config

CURRENT_USER = ENV['SUDO_USER'].nil? ? ENV['USER'] : ENV['SUDO_USER']

#-----------------------------------------------------------------------------------------------------------------------
# Add Repositories

apt_repository 'nemo' do
  uri 'ppa:webupd8team/nemo'
  distribution node['lsb']['codename']
end

#-----------------------------------------------------------------------------------------------------------------------
# Nemo file manager

%w(
  nemo
  nemo-compare
  nemo-dropbox
  nemo-emblems
  nemo-filename-repairer
  nemo-fileroller
  nemo-image-converter
  nemo-share
).each do |pkg|
  package pkg do
    action :install
    notifies :run, 'bash[setup nemo]'
  end
end

%w(
  nautilus
  nautilus-actions
  nautilus-admin
  nautilus-columns
  nautilus-compare
  nautilus-dbg
  nautilus-dropbox
  nautilus-emblems
  nautilus-filename-repairer
  nautilus-gtkhash
  nautilus-hide
  nautilus-ideviceinfo
  nautilus-image-converter
  nautilus-image-manipulator
  nautilus-owncloud
  nautilus-qdigidoc
  nautilus-script-audio-convert
  nautilus-script-collection-svn
  nautilus-script-debug
  nautilus-script-manager
  nautilus-sdcripts-manager
  nautilus-sendto
  nautilus-share
  nautilus-wipe
).each do |pkg|
  package pkg do
    action :purge
    notifies :run, 'bash[setup nemo]'
  end
end

bash 'setup nemo' do
  user CURRENT_USER
  code <<-EOH
    # Prevent Nautilus from handling the desktop icons (and use Nemo instead).
    gsettings set org.gnome.desktop.background show-desktop-icons false
    # Set Nemo as the default file manager (replacing Nautilus).
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
  EOH
  action :nothing
end

# %w(
#   nemo
#   nemo-*
# ).each do |pkg|
# package pkg do
#   action :purge
#   notifies :run, 'bash[remove nemo]'
# end

# bash 'remove nemo' do
#   user CURRENT_USER
#   code <<-EOH
#     # Let Nautilus draw the desktop icons.
#     gsettings set org.gnome.desktop.background show-desktop-icons true
#     # Set Nautilus as the default file manager.
#     xdg-mime default nautilus.desktop inode/directory application/x-gnome-saved-search
#   EOH
#   action :nothing
# end

# apt_repository 'nemo' do
#   uri 'ppa:webupd8team/nemo'
#   distribution node['lsb']['codename']
#   action :remove
# end
