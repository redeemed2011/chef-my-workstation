#
# Cookbook Name:: my_workstation
# Recipe:: default
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
# Run Recipes

# Optimize apt.
include_recipe 'apt::default'
include_recipe 'apt::unattended-upgrades'

#-----------------------------------------------------------------------------------------------------------------------
# Add Repositories

template '/etc/apt/sources.list' do
  source 'apt/sources.list.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[apt-get update]', :immediately
end

# apt_repository 'apt-fast' do
#   uri 'ppa:saiarcot895/myppa'
#   distribution node.deep_fetch(:lsb, :codename)
# end

apt_repository 'git-core' do
  uri 'ppa:git-core/ppa'
  distribution node.deep_fetch(:lsb, :codename)
  components ['main']
end

# Packages in this PPA: audacious, ap-hotspot, awn-applet-radio, awn-applet-wm, calise, cmus, dockbarx,
# dockbarx-themes-extra, dropbox-share, emerald, exaile, fbmessenger, gnome-subtitles, gnome-window-applets, grsync,
# grive, gthumb, launchpad-getkeys, mc, mdm (Mint Display Manager), minitunes, minitube, musique, notifyosdconfig,
# nautilus-columns, powertop, ppa-purge, rosa-media-player, fixed pulseaudio-equalizer, subtitleeditor, syncwall,
# umplayer, unity-reboot, wimlib, youtube-dl, xfce4-dockbarx-plugin, xournal, yad, yarock and others. Almost all
# packages are updated to their latest version.
apt_repository 'webupd8' do
  uri 'ppa:nilarimogard/webupd8'
  distribution node.deep_fetch(:lsb, :codename)
end

apt_repository 'ubuntu-make' do
  uri 'ppa:ubuntu-desktop/ubuntu-make'
  distribution node.deep_fetch(:lsb, :codename)
end

#-----------------------------------------------------------------------------------------------------------------------
# Manage General Packages

# Desirables.
# * gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard: needed for arc-theme, vertex-theme or
#   ceti-2-theme.
# * wmctrl: allows one to do nifty things like make windows stay always on top via custom hotkeys (or one could just
#   press ALT+SPACE,T); "wmctrl -r :ACTIVE: -b toggle,above"
# * steam: usually asks the user to agree to a EULA, so likely will need to run "dpkg-reconfigure steam" after chef run.
%w(
  git
  htop
  intel-microcode iucode-tool
  iotop
  linux-headers-generic
  powerline fonts-powerline
  python3-setuptools
  p7zip-full p7zip-rar
  shellcheck
  unattended-upgrades
  ubuntu-make
).each do |pkg|
  # apt-fast
  # arc-theme ceti-2-theme vertex-theme
  package pkg do
    action :install
  end
end

# Ubuntu restricted extras without flash.
# 'ubuntu-restricted-extras' installs flash too, which we do not want. Instead skip this group and install:
#   lame unrar gstreamer1.0-fluendo-mp3 gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
#   gstreamer1.0-fluendo-mp3 libdvdread4 libk3b6-extracodecs  oxideqt-codecs-extra libavcodec-extra
#   libavcodec-ffmpeg-extra56 libdvd-pkg
%w(
  lame
  unrar
  gstreamer1.0-fluendo-mp3
  gstreamer1.0-plugins-bad
  gstreamer1.0-plugins-ugly
  gstreamer1.0-libav
  gstreamer1.0-fluendo-mp3
  libdvdread4
  libk3b6-extracodecs
  oxideqt-codecs-extra
  libavcodec-extra
  libavcodec-ffmpeg-extra56
  libdvd-pkg
).each do |pkg|
  package pkg do
    action :install
  end
end

bash 'Install DVD Decoding' do
  user CURRENT_USER
  code <<-EOH
    bash /usr/share/doc/libdvdread4/install-css.sh
  EOH
  only_if 'test -e /usr/share/doc/libdvdread4/install-css.sh'
end

# Ensure flash is not installed.
%w(
  flashplayer-nonfree
  flashplugin-installer
).each do |pkg|
  package pkg do
    action :purge
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# Misc

# # Install our customized bashrc.
# cookbook_file '/etc/bash.bashrc' do
#   source 'ubuntu.bashrc'
#   owner 'root'
#   group 'root'
#   mode '0644'
# end
