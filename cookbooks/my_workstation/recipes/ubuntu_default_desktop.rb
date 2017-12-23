#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# UBUNTU ONLY!
return unless platform?('debian') 

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

apt_repository 'enpass' do
  uri 'http://repo.sinew.in/'
  distribution ''
  components %w(stable main)
  key 'http://repo.sinew.in/keys/enpass-linux.key'
end

apt_repository 'y-ppa-manager' do
  uri 'ppa:webupd8team/y-ppa-manager'
  distribution node.deep_fetch(:lsb, :codename)
end


apt_repository 'syncthing' do
  uri 'http://apt.syncthing.net/'
  distribution 'syncthing'
  components %w(release)
  key 'https://syncthing.net/release-key.txt'
  trusted true
end

# Is chef running in a baremetal system?
if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host' then
  apt_repository 'virtualbox' do
    uri 'http://download.virtualbox.org/virtualbox/debian'
    distribution node.deep_fetch(:lsb, :codename)
    components %w(contrib non-free)
    key 'http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc'
    trusted true
  end

  apt_repository 'open-source-graphics-drivers' do
    uri 'ppa:oibaf/graphics-drivers'
    distribution node.deep_fetch(:lsb, :codename)
    key 'http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x957D2708A03A4626'
  end

  apt_repository 'ubuntu-wine' do
    uri 'ppa:ubuntu-wine/ppa'
    distribution node.deep_fetch(:lsb, :codename)
    components %w(main)
  end

  # NVidia 364 on this repo was unstable. 361 (current at the time of this writing) was older than Canonical's repo.
  apt_repository 'graphics-drivers' do
    uri 'ppa:graphics-drivers/ppa'
    distribution node.deep_fetch(:lsb, :codename)
  end
end

# Some of these themes are not working in Gnome 3.20 at the time of this writing, so not using this ppa.
apt_repository 'horst3180' do
  uri 'http://download.opensuse.org/repositories/home:/Horst3180/xUbuntu_16.04/'
  distribution '/'
  components []
  key 'http://download.opensuse.org/repositories/home:Horst3180/xUbuntu_16.04/Release.key'
  trusted true
end

# Allows installation of apps like:
# * xdman-downloader
apt_repository 'noobslab-apps' do
  uri 'ppa:noobslab/apps'
  distribution node.deep_fetch(:lsb, :codename)
end

apt_repository 'noobslab-icons' do
  uri 'ppa:noobslab/icons'
  distribution node.deep_fetch(:lsb, :codename)
end

apt_repository 'noobslab-icons2' do
  uri 'ppa:noobslab/icons2'
  distribution node.deep_fetch(:lsb, :codename)
end

# July 2016: this package is failing to install.
# # Repo for 'screencloud'.
# apt_repository 'screencloud' do
#   uri 'http://download.opensuse.org/repositories/home:/olav-st/xUbuntu_15.10/'
#   distribution '/'
#   key 'http://download.opensuse.org/repositories/home:/olav-st/xUbuntu_15.10/Release.key'
# end

# Vibrancy colors icons.
apt_repository 'ravefinity-project' do
  uri 'ppa:ravefinity-project/ppa'
  distribution node.deep_fetch(:lsb, :codename)
  components %w(main)
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
  thunderbird
  xserver-xorg-video-intel
  yelp
).each do |pkg|
  # webbrowser-app : required by unit-tweak-tool :/
  package pkg do
    action :purge
    # notifies :restart, 'service[gdm]', :delayed
  end
end

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
  vibrancy-colors antu-universal-icons
  dconf-editor
  enpass
  syncthing
  pinta
  gksu
  vertex-icons gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard
  vlc browser-plugin-vlc
  wmctrl
  synaptic
  y-ppa-manager
  arc-theme ceti-2-theme vertex-theme arc-icons
  xdman-downloader
).each do |pkg|
  # screencloud  # UPDATE: July 2016: this package is failing to install.
  # apt-fast
  package pkg do
    action :install
  end
end

# Is chef running in a baremetal system?
if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host' then
  %w(
    mesa-va-drivers mesa-vdpau-drivers xserver-xorg-video-nouveau
    nvidia-367 nvidia-prime prime-indicator
    virtualbox-5.1
  ).each do |pkg|
    package pkg do
      action :install
    end
  end
end

# Install unity-reboot only if the user has unity installed.
package 'unity-reboot' do
  action :install
  only_if 'which unity'
end

#-----------------------------------------------------------------------------------------------------------------------
# Google Chrome.

bash 'add google-chrome key' do
  code <<-EOH
    wget -q -O- https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  EOH
  not_if 'dpkg -s google-chrome-stable'
end

remote_file '/tmp/google-chrome.deb' do
  source 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
  not_if 'dpkg -s google-chrome-stable'
end

dpkg_package 'google-chrome' do
  source '/tmp/google-chrome.deb'
  not_if 'dpkg -s google-chrome-stable'
  action :install
end

#-----------------------------------------------------------------------------------------------------------------------
# Create script for user to run later.

cookbook_file "#{ENV['HOME']}/user-extras.sh" do
  source 'ubuntu.user-extras.sh'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0744'
end

#-----------------------------------------------------------------------------------------------------------------------
# Prune the unwanted

%w(
  /usr/share/backgrounds/Xerus_Wallpaper_Grey_*
).each do |fname|
  file fname do
    action :delete
    path fname
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# General configuration changes

bash 'disable touchpad when external mouse is present' do
  code <<-EOH
    gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled-on-external-mouse
  EOH
end
