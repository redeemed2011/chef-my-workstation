#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop_personal
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

#-----------------------------------------------------------------------------------------------------------------------
# Config

CURRENT_USER = ENV['SUDO_USER'].nil? ? ENV['USER'] : ENV['SUDO_USER']
log "CURRENT_USER is '#{CURRENT_USER}' because SUDO_USER is '#{ENV['SUDO_USER']}' & USER is '#{ENV['USER']}'."
node.default['authorization']['sudo']['users'] = %W(#{CURRENT_USER})

#-----------------------------------------------------------------------------------------------------------------------
# Run Recipes

#...

#-----------------------------------------------------------------------------------------------------------------------
# Add Repositories

apt_repository 'insync' do
  uri 'http://apt.insynchq.com/ubuntu'
  distribution node['lsb']['codename']
  components %w(non-free contrib)
  key 'https://d2t3ff60b2tol4.cloudfront.net/services@insynchq.com.gpg.key'
end

apt_repository 'ubuntu-wine' do
  uri 'ppa:ubuntu-wine/ppa'
  distribution node['lsb']['codename']
  components %w(main)
  not_if ( node.virtualization.system == 'host' )
end

#-----------------------------------------------------------------------------------------------------------------------
# Manage General Packages

# Desirables.
# * nvidia-367: "long lived branch" of drivers from nvidia.
# * pinta: Paint.NET inspired image editor.
# * gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard: needed for arc-theme, vertex-theme or
#   ceti-2-theme.
# * wmctrl: allows one to do nifty things like make windows stay always on top via custom hotkeys (or one could just
#   press ALT+SPACE,T); "wmctrl -r :ACTIVE: -b toggle,above"
# * steam: usually asks the user to agree to a EULA, so likely will need to run "dpkg-reconfigure steam" after chef run.
# * screencloud: screenshot util. UPDATE: July 2016: this package is failing to install.
%w(
  insync
  nautilus-dropbox
  steam
).each do |pkg|
  # screencloud  # UPDATE: July 2016: this package is failing to install.
  # apt-fast
  package pkg do
    action :install
  end
end

# Is chef running in a baremetal system?
if ( node.virtualization.system == 'host' ) then
  %w(
    playonlinux wine winetricks
  ).each do |pkg|
    package pkg do
      action :install
    end
  end
end

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

#-----------------------------------------------------------------------------------------------------------------------
# General configuration changes

bash 'disable touchpad when external mouse is present' do
  code <<-EOH
    gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled-on-external-mouse
  EOH
  not_if ( node.virtualization.system == 'host' )
end
