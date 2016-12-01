#
# Cookbook Name:: my_workstation
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

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

# Configure NTP client.
include_recipe 'ntp::default'

# Configure SSH/SSHD.
include_recipe 'openssh::default'

# Set the time.
include_recipe 'system::default'

# Configure sudo.
include_recipe 'sudo::default'

# Install Ruby system-wide via the RubyEnv project.
unless File.exist?('/usr/local/rbenv/shims/ruby')
  include_recipe 'ruby_build::default'
  include_recipe 'ruby_rbenv::system'
end

# Install python & pip.
cmd = Mixlib::ShellOut.new('dpkg -s python').run_command
unless cmd.exitstatus == 0 && File.exist?('/usr/local/bin/pip')
  include_recipe 'poise-python::default'
end

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
#   distribution node['lsb']['codename']
# end

apt_repository 'git-core' do
  uri 'ppa:git-core/ppa'
  distribution node['lsb']['codename']
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
  distribution node['lsb']['codename']
end

apt_repository 'ubuntu-make' do
  uri 'ppa:ubuntu-desktop/ubuntu-make'
  distribution node['lsb']['codename']
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
# Docker

docker_installation_script 'default' do
  # repo node['docker']['repo']
  action :create
end

# Add the current user to the docker group.
group 'docker' do
  action :create
  members %W(#{CURRENT_USER})
end

#-----------------------------------------------------------------------------------------------------------------------
# General utils

# Set the default ruby version system wide.
rbenv_global '2.3.0' do
  action :create
end

# python_package 'ps_mem' do
#   # version '1.0.0'
# end

#-----------------------------------------------------------------------------------------------------------------------
# Powerline.
# NOTE: Some changes are added to /etc/bash.bashrc.

# Why both dirs? To ensure permissions are proper.
%W(
  #{ENV['HOME']}/.config/powerline
  #{ENV['HOME']}/.config/powerline/themes/shell/
).each do |dir|
  directory dir do
    owner CURRENT_USER
    group CURRENT_USER
    recursive true
    action :create
  end
end

cookbook_file "#{ENV['HOME']}/.config/powerline/config.json" do
  source 'powerline/config.json'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0644'
end

cookbook_file "#{ENV['HOME']}/.config/powerline/themes/shell/personal.json" do
  source 'powerline/themes-shell-personal.json'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0644'
end

#-----------------------------------------------------------------------------------------------------------------------
# Snapper related.
# https://wiki.archlinux.org/index.php/Snapper

# printf "\n\nEnable Snapper for snapshots.\n"
# sudo systemctl start snapper-timeline.timer snapper-cleanup.timer
# sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer

#-----------------------------------------------------------------------------------------------------------------------
# User management

# Install our customized bashrc.
cookbook_file '/etc/bash.bashrc' do
  source 'bash.bashrc'
  owner 'root'
  group 'root'
  mode '0644'
end
