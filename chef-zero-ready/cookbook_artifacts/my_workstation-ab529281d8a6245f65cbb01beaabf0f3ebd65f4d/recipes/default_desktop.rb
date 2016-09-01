#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

#-----------------------------------------------------------------------------------------------------------------------
# Config

CURRENT_USER = ENV['SUDO_USER'].nil? ? ENV['USER'] : ENV['SUDO_USER']
log "CURRENT_USER is '#{CURRENT_USER}' because SUDO_USER is '#{ENV['SUDO_USER']}' & USER is '#{ENV['USER']}'."
node.default['authorization']['sudo']['users'] = %W(#{CURRENT_USER})

#-----------------------------------------------------------------------------------------------------------------------
# Run Recipes

# Install vagrant.
cmd = Mixlib::ShellOut.new('dpkg -s vagrant').run_command
include_recipe 'vagrant::default' unless cmd.exitstatus == 0

#-----------------------------------------------------------------------------------------------------------------------
# Add Repositories

apt_repository 'enpass' do
  uri 'http://repo.sinew.in/'
  distribution ''
  components %w(stable main)
  key 'http://repo.sinew.in/keys/enpass-linux.key'
end

apt_repository 'sublime-text-3' do
  uri 'ppa:webupd8team/sublime-text-3'
  distribution node['lsb']['codename']
end

apt_repository 'atom' do
  uri 'ppa:webupd8team/atom'
  distribution node['lsb']['codename']
end

apt_repository 'y-ppa-manager' do
  uri 'ppa:webupd8team/y-ppa-manager'
  distribution node['lsb']['codename']
end

# Is chef running in a baremetal system?
if ( node.virtualization.system == 'host' ) then
  apt_repository 'virtualbox' do
    uri 'http://download.virtualbox.org/virtualbox/debian'
    distribution node['lsb']['codename']
    components %w(contrib non-free)
    key 'http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc'
    trusted true
  end

  apt_repository 'open-source-graphics-drivers' do
    uri 'ppa:oibaf/graphics-drivers'
    distribution node['lsb']['codename']
    key 'http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x957D2708A03A4626'
  end

  apt_repository 'ubuntu-wine' do
    uri 'ppa:ubuntu-wine/ppa'
    distribution node['lsb']['codename']
    components %w(main)
  end

  # NVidia 364 on this repo was unstable. 361 (current at the time of this writing) was older than Canonical's repo.
  apt_repository 'graphics-drivers' do
    uri 'ppa:graphics-drivers/ppa'
    distribution node['lsb']['codename']
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

apt_repository 'noobslab-apps' do
  uri 'ppa:noobslab/apps'
  distribution node['lsb']['codename']
end

apt_repository 'noobslab-icons' do
  uri 'ppa:noobslab/icons'
  distribution node['lsb']['codename']
end

apt_repository 'noobslab-icons2' do
  uri 'ppa:noobslab/icons2'
  distribution node['lsb']['codename']
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
  distribution node['lsb']['codename']
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
  atom
  dconf-editor
  enpass
  pinta
  gksu
  sublime-text-installer
  vertex-icons gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard
  vlc browser-plugin-vlc
  wmctrl
  synaptic
  y-ppa-manager
  arc-theme ceti-2-theme vertex-theme arc-icons
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

# Add user to the vboxusers (virtualbox) group.
# TODO: fix this so that it doesn't add root but rather the actual user.
group 'vboxusers' do
  action :create
  members %W(#{CURRENT_USER})
  not_if ( node.virtualization.system == 'host' )
end

# Disable copy-on-write on folders that have VMs.
%W(
  #{ENV['HOME']}/.vagrant.d/boxes
  #{ENV['HOME']}/.vagrant.d/tmp
).each do |dir|
  directory dir do
    owner CURRENT_USER
    group CURRENT_USER
    action :create
    recursive true
    notifies :run, "execute[chattr #{dir}]"
  end
  execute "chattr #{dir}" do
    command "chattr +C '#{dir}'"
    action :nothing
  end
end

if ( node.virtualization.system == 'host' ) then
  %W(
    #{ENV['HOME']}/VirtualBox\ VMs
  ).each do |dir|
    directory dir do
      owner CURRENT_USER
      group CURRENT_USER
      action :create
      recursive true
      notifies :run, "execute[chattr #{dir}]"
    end
    execute "chattr #{dir}" do
      command "chattr +C '#{dir}'"
      action :nothing
    end
  end
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
# GitKraken - Git GUI.

remote_file '/tmp/gitkraken.deb' do
  source 'https://release.gitkraken.com/linux/gitkraken-amd64.deb'
  not_if 'dpkg -s gitkraken'
end

dpkg_package 'gitkraken' do
  source '/tmp/gitkraken.deb'
  not_if 'dpkg -s gitkraken'
  action :install
end

# #-----------------------------------------------------------------------------------------------------------------------
# # Vertex Theme
#
# # We don't want to delete the theme if we previously installed it from git.
# %w(
#   /usr/share/themes/Vertex
#   /usr/share/themes/Vertex-Dark
#   /usr/share/themes/Vertex-Light
#   /usr/share/themes/Vertex-Gnome-Shell*
#   /usr/share/themes/Vertex-Cinnamon
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#     not_if 'test -d /tmp/vertex-theme'
#   end
# end
#
# %W(
#   #{ENV['HOME']}/.local/share/themes/Vertex
#   #{ENV['HOME']}/.local/share/themes/Vertex-Dark
#   #{ENV['HOME']}/.local/share/themes/Vertex-Light
#   #{ENV['HOME']}/.local/share/themes/Vertex-Gnome-Shell*
#   #{ENV['HOME']}/.local/share/themes/Vertex-Cinnamon
#   #{ENV['HOME']}/.themes/Vertex
#   #{ENV['HOME']}/.themes/Vertex-Dark
#   #{ENV['HOME']}/.themes/Vertex-Light
#   #{ENV['HOME']}/.themes/Vertex-Gnome-Shell*
#   #{ENV['HOME']}/.themes/Vertex-Cinnamon
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#   end
# end
#
# # We don't want to delete the theme's source if we've previously downloaded it.
# %w(
#   /tmp/vertex-theme
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#     not_if 'test -d /usr/share/themes/Vertex'
#   end
# end
#
# git '/tmp/vertex-theme' do
#   repository 'https://github.com/horst3180/vertex-theme'
#   depth 1
#   reference 'master'
#   action :sync
#   notifies :run, 'bash[install-vertex-theme]'
# end
#
# bash 'install-vertex-theme' do
#   cwd '/tmp/vertex-theme'
#   code <<-EOC
#     ./autogen.sh --prefix=/usr
#     sudo make install
#   EOC
#   # creates '/usr/share/themes/Vertex'
#   action :nothing
# end

# #-----------------------------------------------------------------------------------------------------------------------
# # Ceti 2 Theme
# # NOTE: Will error on Gnome 3.20 at the time of this writing, thus no longer attempting to install.
#
# # We don't want to delete the theme if we previously installed it from git.
# %w(
#   /usr/share/themes/Ceti-2
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#     not_if 'test -d /tmp/ceti-2-theme'
#   end
# end
#
# %W(
#   #{ENV['HOME']}/.local/share/themes/Ceti-2
#   #{ENV['HOME']}/.themes/Ceti-2
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#   end
# end
#
# # We don't want to delete the theme's source if we've previously downloaded it.
# %w(
#   /tmp/ceti-2-theme
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#     not_if 'test -d /tmp/ceti-2-theme'
#   end
# end
#
# git '/tmp/ceti-2-theme' do
#   repository 'https://github.com/horst3180/ceti-2-theme'
#   depth 1
#   reference 'master'
#   action :sync
#   notifies :run, 'bash[install-ceti-2-theme]'
# end
#
# bash 'install-ceti-2-theme' do
#   cwd '/tmp/ceti-2-theme'
#   code <<-EOC
#     set +e # ignore errors
#     ./autogen.sh --prefix=/usr
#     sudo make install
#   EOC
#   # creates '/usr/share/themes/Ceti-2'
#   action :nothing
# end

# #-----------------------------------------------------------------------------------------------------------------------
# # Arc Theme
#
# # We don't want to delete the theme if we previously installed it from git.
# %w(
#   /usr/share/themes/Arc
#   /usr/share/themes/Arc-Dark
#   /usr/share/themes/Arc-Darker
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#     not_if 'test -d /tmp/arc-theme'
#   end
# end
#
# %W(
#   #{ENV['HOME']}/.local/share/themes/Arc
#   #{ENV['HOME']}/.local/share/themes/Arc-Dark
#   #{ENV['HOME']}/.local/share/themes/Arc-Darker
#   #{ENV['HOME']}/.themes/Arc
#   #{ENV['HOME']}/.themes/Arc-Dark
#   #{ENV['HOME']}/.themes/Arc-Darker
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#   end
# end
#
# # We don't want to delete the theme's source if we've previously downloaded it.
# %w(
#   /tmp/arc-theme
# ).each do |dir|
#   directory dir do
#     recursive true
#     action :delete
#     not_if 'test -d /usr/share/themes/Arc'
#   end
# end
#
# git '/tmp/arc-theme' do
#   repository 'https://github.com/horst3180/arc-theme'
#   depth 1
#   reference 'master'
#   action :sync
#   notifies :run, 'bash[install-arc-theme]'
# end
#
# bash 'install-arc-theme' do
#   cwd '/tmp/arc-theme'
#   code <<-EOC
#     ./autogen.sh --prefix=/usr
#     sudo make install
#   EOC
#   # creates '/usr/share/themes/Arc'
#   action :nothing
# end

#-----------------------------------------------------------------------------------------------------------------------
# Yosembiance Theme

# We don't want to delete the theme if we previously installed it from git.
%w(
  /usr/share/themes/Yosembiance-Atomic-Blue
  /usr/share/themes/Yosembiance-Atomic-Orange
  /usr/share/themes/Yosembiance-Kraken-Blue
  /usr/share/themes/Yosembiance-Ubuntu-Blue
  /usr/share/themes/Yosembiance-Ubuntu-Orange
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if 'test -d /tmp/Yosembiance'
  end
end

# We don't want to delete the theme's source if we've previously downloaded it.
directory '/tmp/Yosembiance' do
  recursive true
  action :delete
  not_if 'test -d /usr/share/themes/Yosembiance-Atomic-Blue'
end

git '/tmp/Yosembiance' do
  repository 'https://github.com/bsundman/Yosembiance.git'
  depth 1
  reference 'master'
  action :sync
end

%w(
  /tmp/Yosembiance/Yosembiance-Atomic-Blue
  /tmp/Yosembiance/Yosembiance-Atomic-Orange
  /tmp/Yosembiance/Yosembiance-Kraken-Blue
  /tmp/Yosembiance/Yosembiance-Ubuntu-Blue
  /tmp/Yosembiance/Yosembiance-Ubuntu-Orange
).each do |dir|
  # remote_directory "/usr/share/themes/#{File.basename(dir)}" do
  bash "install theme: #{File.basename(dir)}" do
    code <<-EOC
      rsync -r --inplace --links --times --delete-during --force --prune-empty-dirs \
        "#{dir}/" "/usr/share/themes/#{File.basename(dir)}"
    EOC
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# Captiva Icons

# We don't want to delete the theme if we previously installed it from git.
directory '/usr/share/icons/Captiva' do
  recursive true
  action :delete
  not_if 'test -d /tmp/captiva-icon-theme'
end

# We don't want to delete the theme's source if we've previously downloaded it.
directory '/tmp/captiva-icon-theme' do
  recursive true
  action :delete
  not_if 'test -d /usr/share/icons/Captiva'
end

git '/tmp/captiva-icon-theme' do
  repository 'https://github.com/captiva-project/captiva-icon-theme.git'
  depth 1
  reference 'master'
  action :sync
end

bash 'install icons: Captiva' do
  code <<-EOC
    rsync -r --inplace --links --times --delete-during --force --prune-empty-dirs \
      "/tmp/captiva-icon-theme/Captiva/" \
      '/usr/share/icons/Captiva'
  EOC
end

#-----------------------------------------------------------------------------------------------------------------------
# X11 Cursors

Dir.foreach("#{Chef::Config[:file_cache_path]}/cookbooks/my_workstation/files/cursors") do |cursor|
  next if cursor == '.' || cursor == '..'

  tarball "#{Chef::Config[:file_cache_path]}/cookbooks/my_workstation/files/cursors/#{cursor}" do
    destination '/usr/share/icons/'
    owner 'root'
    group 'root'
    # extract_list %W( * )
    # umask 022 # Will be applied to perms in archive
    action :extract
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# Snapper related.
# https://wiki.archlinux.org/index.php/Snapper

# # Install snapper gui.
# sudo git clone https://github.com/ricardo-vieira/snapper-gui/ /opt/snapper-gui
# pushd /opt/snapper-gui
# sudo python3 setup.py install
# popd
# # Fix snapper gui to launch with sudo.
# sudo sed -i 's/^Exec=.*/Exec=gksudo snapper-gui/i' /usr/share/applications/snapper-gui.desktop

#-----------------------------------------------------------------------------------------------------------------------
# User management

# Allow vagrant to sudo.
cookbook_file '/etc/sudoers.d/vagrant' do
  source 'sudoers.d/vagrant'
  owner 'root'
  group 'root'
  mode '0440'
end

# Install our customized bashrc.
cookbook_file '/etc/bash.bashrc' do
  source 'bash.bashrc'
  owner 'root'
  group 'root'
  mode '0644'
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
# BTSync

directory "#{ENV['HOME']}/btsync/shares/" do
  owner CURRENT_USER
  group CURRENT_USER
  recursive true
  action :create
end

# Attempt to download the latest BTSync.
remote_file "#{ENV['HOME']}/btsync/installer.tar.gz" do
  owner CURRENT_USER
  group CURRENT_USER
  source 'https://download-cdn.getsync.com/stable/linux-x64/BitTorrent-Sync_x64.tar.gz'
  # checksum 'sha256checksum'
end

# If the download fails, fall back to the included installer.
cookbook_file "#{ENV['HOME']}/btsync/installer.tar.gz" do
  source 'files/BitTorrent-Sync_x64.tar.gz'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0644'
  not_if "test -e '#{ENV['HOME']}/btsync/installer.tar.gz'"
end

tarball "#{ENV['HOME']}/btsync/installer.tar.gz" do
  destination "#{ENV['HOME']}/btsync/"
  owner CURRENT_USER
  group CURRENT_USER
  # extract_list %W( * )
  # umask 022 # Will be applied to perms in archive
  action :extract
end

cookbook_file '/usr/share/applications/btsync.desktop' do
  source 'applications/btsync.desktop'
  owner 'root'
  group 'root'
  mode '0644'
end

directory "#{ENV['HOME']}/.config/autostart/" do
  owner CURRENT_USER
  group CURRENT_USER
  recursive true
  action :create
end

template "#{ENV['HOME']}/.config/autostart/btsync.desktop" do
  source '.config/autostart/btsync.desktop.erb'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0664'
end

#-----------------------------------------------------------------------------------------------------------------------
# General configuration changes

bash 'disable touchpad when external mouse is present' do
  code <<-EOH
    gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled-on-external-mouse
  EOH
end

# # Attempt to fix permissions on the user's home folder.
# directory ENV['HOME'] do
#   owner CURRENT_USER
#   group CURRENT_USER
#   recursive true
#   action :create
# end

# This is not idempotent.
bash 'fix perms on home' do
  # user CURRENT_USER
  code <<-EOH
    find #{ENV['HOME']} -user root -exec chown --no-dereference #{CURRENT_USER} {} +;
    find #{ENV['HOME']} -group root -exec chgrp --no-dereference #{CURRENT_USER} {} +;
  EOH
end
