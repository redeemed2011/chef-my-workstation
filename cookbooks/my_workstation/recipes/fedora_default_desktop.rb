#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# FEDORA ONLY!
return unless platform_family?('fedora') 

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

if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host' then
  package "Bumblebee General Repo" do 
    source "http://install.linux.ncsu.edu/pub/yum/itecs/public/bumblebee/fedora#{platform_version}/noarch/bumblebee-release-1.2-1.noarch.rpm";
    provider Chef::Provider::Package::Rpm
    ignore_failure true
  end
  
  package "Bumblebee Managed NVidia repo" do 
    source "http://install.linux.ncsu.edu/pub/yum/itecs/public/bumblebee-nonfree/fedora#{platform_version}/noarch/bumblebee-nonfree-release-1.2-1.noarch.rpm"
    provider Chef::Provider::Package::Rpm
    ignore_failure true
  end

  package "Virtualbox repo" do 
    source 'http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo'
    provider Chef::Provider::Package::Rpm
    ignore_failure true
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# Manage General Packages

# Never wanted.
%w(
  aisleriot
  gnome-calendar
  gnome-mahjongg
  gnome-mines
  gnome-sudoku
).each do |pkg|
  package pkg do
    action :purge
    # notifies :restart, 'service[gdm]', :delayed
  end
end

# Desirables.
# * nvidia drivers: bumblebee-nvidia bbswitch-dkms primus VirtualGL.x86_64 VirtualGL.i686 primus.x86_64 primus.i686 intel-gpu-tools
# * pinta: Paint.NET inspired image editor.
# * gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard: needed for arc-theme, vertex-theme or
#   ceti-2-theme.
# * steam: usually asks the user to agree to a EULA, so likely will need to run "dpkg-reconfigure steam" after chef run.
# * screencloud: screenshot util. UPDATE: July 2016: this package is failing to install.
%w(
  vlc vlc-extras
  dconf-editor
  pinta
).each do |pkg|
  # google-chrome-stable
  package pkg do
    action :install
  end
end

# Is chef running in a baremetal system?
if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host' then
  %w(
    bumblebee-nvidia bbswitch-dkms primus VirtualGL.x86_64 VirtualGL.i686 primus.x86_64 primus.i686 intel-gpu-tools
    virtualbox-5.1 binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms
  ).each do |pkg|
    package pkg do
      action :install
    end
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# Fedy util.

bash 'Install fedy util' do
  # user CURRENT_USER
  code <<-EOH
    wget -O- http://folkswithhats.org/fedy-installer | bash -s
  EOH
  unless 'which fedy'
end

#-----------------------------------------------------------------------------------------------------------------------
# Google Chrome.

# # Installs Google Chrome & it's repo?
# package "Google Chrome repo" do 
#   source 'https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm'
#   provider Chef::Provider::Package::Rpm
#   ignore_failure true
# end
bash 'Install Google Chrome' do
  # user CURRENT_USER
  code <<-EOH
    wget -O- https://raw.githubusercontent.com/folkswithhats/fedy/master/plugins/chrome.plugin/install.sh | bash -s
  EOH
  unless 'which google-chrome'
end



# bash 'add google-chrome key' do
#   code <<-EOH
#     dnf -y --nogpgcheck install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
#   EOH
#   not_if 'dpkg -s google-chrome-stable'
# end

# remote_file '/tmp/google-chrome.deb' do
#   source 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
#   not_if 'dpkg -s google-chrome-stable'
# end

# dpkg_package 'google-chrome' do
#   source '/tmp/google-chrome.deb'
#   not_if 'dpkg -s google-chrome-stable'
#   action :install
# end

#-----------------------------------------------------------------------------------------------------------------------
# General configuration changes

# bash 'disable touchpad when external mouse is present' do
#   code <<-EOH
#     gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled-on-external-mouse
#   EOH
# end

# Add the current user to the bumblebee group.
group 'bumblebee' do
  action :create
  members %W(#{CURRENT_USER})
end
