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

# Install vagrant.
cmd = Mixlib::ShellOut.new('dpkg -s vagrant').run_command
if cmd.exitstatus != 0
  include_recipe 'vagrant::default'
end

#-----------------------------------------------------------------------------------------------------------------------
# Add Repositories

apt_repository 'enpass' do
  uri 'http://repo.sinew.in/'
  distribution ''
  components %w(stable main)
  key 'http://repo.sinew.in/keys/enpass-linux.key'
end

apt_repository 'insync' do
  uri 'http://apt.insynchq.com/ubuntu'
  distribution node['lsb']['codename']
  components %w(non-free contrib)
  key 'https://d2t3ff60b2tol4.cloudfront.net/services@insynchq.com.gpg.key'
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

apt_repository 'virtualbox' do
  uri 'http://download.virtualbox.org/virtualbox/debian'
  distribution node['lsb']['codename']
  components %w(contrib non-free)
  key 'http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc'
  trusted true
end

# # Some of these themes are not working in Gnome 3.20 at the time of this writing, so not using this ppa.
# apt_repository 'horst3180' do
#   uri 'http://download.opensuse.org/repositories/home:/Horst3180/xUbuntu_16.04/'
#   distribution '/'
#   components []
#   key 'http://download.opensuse.org/repositories/home:Horst3180/xUbuntu_16.04/Release.key'
#   trusted true
# # echo 'deb http://download.opensuse.org/repositories/home:/Horst3180/xUbuntu_16.04/ /' | \
# #   sudo tee /etc/apt/sources.list.d/vertex-and-arc-theme.list
# # wget -q http://download.opensuse.org/repositories/home:Horst3180/xUbuntu_16.04/Release.key -O- | \
# #   sudo apt-key add -
# end

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

apt_repository 'open-source-graphics-drivers' do
  uri 'ppa:oibaf/graphics-drivers'
  distribution node['lsb']['codename']
  key 'http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x957D2708A03A4626'
end

# Vibrancy colors icons.
apt_repository 'ravefinity-project' do
  uri 'ppa:ravefinity-project/ppa'
  distribution node['lsb']['codename']
  components %w(main)
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
# * gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard: needed for arc-theme, vertex-theme or
#   ceti-2-theme.
# * wmctrl: allows one to do nifty things like make windows stay always on top via custom hotkeys (or one could just
#   press ALT+SPACE,T); "wmctrl -r :ACTIVE: -b toggle,above"
# * steam: usually asks the user to agree to a EULA, so likely will need to run "dpkg-reconfigure steam" after chef run.
%w(
  vibrancy-colors antu-universal-icons
  atom
  dconf-editor
  enpass
  gimp
  gksu
  insync
  mesa-va-drivers mesa-vdpau-drivers xserver-xorg-video-nouveau
  nautilus-dropbox
  nvidia-364 nvidia-prime prime-indicator
  steam
  sublime-text-installer
  synaptic
  variety
  vertex-icons gtk2-engines-pixbuf libgtk-3-dev autoconf automake gnome-themes-standard
  virtualbox-5.0
  vlc browser-plugin-vlc
  wmctrl
  xdman
  y-ppa-manager
  playonlinux wine winetricks
).each do |pkg|
  # apt-fast
  # arc-theme ceti-2-theme vertex-theme
  package pkg do
    action :install
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
end

# Disable copy-on-write on folders that have VMs.
%W(
  #{ENV['HOME']}/VirtualBox\ VMs
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

#-----------------------------------------------------------------------------------------------------------------------
# Vertex Theme

# We don't want to delete the theme if we previously installed it from git.
%w(
  /usr/share/themes/Vertex
  /usr/share/themes/Vertex-Dark
  /usr/share/themes/Vertex-Light
  /usr/share/themes/Vertex-Gnome-Shell*
  /usr/share/themes/Vertex-Cinnamon
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if "test -d #{ENV['HOME']}/Downloads/vertex-theme"
  end
end

%W(
  #{ENV['HOME']}/.local/share/themes/Vertex
  #{ENV['HOME']}/.local/share/themes/Vertex-Dark
  #{ENV['HOME']}/.local/share/themes/Vertex-Light
  #{ENV['HOME']}/.local/share/themes/Vertex-Gnome-Shell*
  #{ENV['HOME']}/.local/share/themes/Vertex-Cinnamon
  #{ENV['HOME']}/.themes/Vertex
  #{ENV['HOME']}/.themes/Vertex-Dark
  #{ENV['HOME']}/.themes/Vertex-Light
  #{ENV['HOME']}/.themes/Vertex-Gnome-Shell*
  #{ENV['HOME']}/.themes/Vertex-Cinnamon
).each do |dir|
  directory dir do
    recursive true
    action :delete
  end
end

# We don't want to delete the theme's source if we've previously downloaded it.
%W(
  #{ENV['HOME']}/Downloads/vertex-theme
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if 'test -d /usr/share/themes/Vertex'
  end
end

git "#{ENV['HOME']}/Downloads/vertex-theme" do
  repository 'https://github.com/horst3180/vertex-theme'
  depth 1
  reference 'master'
  action :sync
  notifies :run, 'bash[install-vertex-theme]'
end

bash 'install-vertex-theme' do
  cwd "#{ENV['HOME']}/Downloads/vertex-theme"
  code <<-EOC
    ./autogen.sh --prefix=/usr
    sudo make install
  EOC
  # creates '/usr/share/themes/Vertex'
  action :nothing
end

#-----------------------------------------------------------------------------------------------------------------------
# Ceti 2 Theme
# NOTE: Will error on Gnome 3.20 at the time of this writing, thus no longer attempting to install.

# We don't want to delete the theme if we previously installed it from git.
%w(
  /usr/share/themes/Ceti-2
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if "test -d #{ENV['HOME']}/Downloads/ceti-2-theme"
  end
end

%W(
  #{ENV['HOME']}/.local/share/themes/Ceti-2
  #{ENV['HOME']}/.themes/Ceti-2
).each do |dir|
  directory dir do
    recursive true
    action :delete
  end
end

# We don't want to delete the theme's source if we've previously downloaded it.
%W(
  #{ENV['HOME']}/Downloads/ceti-2-theme
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if 'test -d /usr/share/themes/Vertex'
  end
end

git "#{ENV['HOME']}/Downloads/ceti-2-theme" do
  repository 'https://github.com/horst3180/ceti-2-theme'
  depth 1
  reference 'master'
  action :sync
  notifies :run, 'bash[install-ceti-2-theme]'
end

bash 'install-ceti-2-theme' do
  cwd "#{ENV['HOME']}/Downloads/ceti-2-theme"
  code <<-EOC
    set +e # ignore errors
    ./autogen.sh --prefix=/usr
    sudo make install
  EOC
  # creates '/usr/share/themes/Ceti-2'
  action :nothing
end

#-----------------------------------------------------------------------------------------------------------------------
# Arc Theme

# We don't want to delete the theme if we previously installed it from git.
%w(
  /usr/share/themes/Arc
  /usr/share/themes/Arc-Dark
  /usr/share/themes/Arc-Darker
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if "test -d #{ENV['HOME']}/Downloads/arc-theme"
  end
end

%W(
  #{ENV['HOME']}/.local/share/themes/Arc
  #{ENV['HOME']}/.local/share/themes/Arc-Dark
  #{ENV['HOME']}/.local/share/themes/Arc-Darker
  #{ENV['HOME']}/.themes/Arc
  #{ENV['HOME']}/.themes/Arc-Dark
  #{ENV['HOME']}/.themes/Arc-Darker
).each do |dir|
  directory dir do
    recursive true
    action :delete
  end
end

# We don't want to delete the theme's source if we've previously downloaded it.
%W(
  #{ENV['HOME']}/Downloads/arc-theme
).each do |dir|
  directory dir do
    recursive true
    action :delete
    not_if 'test -d /usr/share/themes/Arc'
  end
end

git "#{ENV['HOME']}/Downloads/arc-theme" do
  repository 'https://github.com/horst3180/arc-theme'
  depth 1
  reference 'master'
  action :sync
  notifies :run, 'bash[install-arc-theme]'
end

bash 'install-arc-theme' do
  cwd "#{ENV['HOME']}/Downloads/arc-theme"
  code <<-EOC
    ./autogen.sh --prefix=/usr
    sudo make install
  EOC
  # creates '/usr/share/themes/Arc'
  action :nothing
end

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
    not_if "test -d #{ENV['HOME']}/Downloads/Yosembiance"
  end
end

# We don't want to delete the theme's source if we've previously downloaded it.
directory "#{ENV['HOME']}/Downloads/Yosembiance" do
  recursive true
  action :delete
  not_if 'test -d /usr/share/themes/Yosembiance-Atomic-Blue'
end

git "#{ENV['HOME']}/Downloads/Yosembiance" do
  repository 'https://github.com/bsundman/Yosembiance.git'
  depth 1
  reference 'master'
  action :sync
end

%W(
  #{ENV['HOME']}/Downloads/Yosembiance/Yosembiance-Atomic-Blue
  #{ENV['HOME']}/Downloads/Yosembiance/Yosembiance-Atomic-Orange
  #{ENV['HOME']}/Downloads/Yosembiance/Yosembiance-Kraken-Blue
  #{ENV['HOME']}/Downloads/Yosembiance/Yosembiance-Ubuntu-Blue
  #{ENV['HOME']}/Downloads/Yosembiance/Yosembiance-Ubuntu-Orange
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
  not_if "test -d #{ENV['HOME']}/Downloads/captiva-icon-theme"
end

# We don't want to delete the theme's source if we've previously downloaded it.
directory "#{ENV['HOME']}/Downloads/captiva-icon-theme" do
  recursive true
  action :delete
  not_if 'test -d /usr/share/icons/Captiva'
end

git "#{ENV['HOME']}/Downloads/captiva-icon-theme" do
  repository 'https://github.com/captiva-project/captiva-icon-theme.git'
  depth 1
  reference 'master'
  action :sync
end

bash "install icons: Captiva" do
  code <<-EOC
    rsync -r --inplace --links --times --delete-during --force --prune-empty-dirs \
      "#{ENV['HOME']}/Downloads/captiva-icon-theme/Captiva/" \
      '/usr/share/icons/Captiva'
  EOC
end

#-----------------------------------------------------------------------------------------------------------------------
# X11 Cursors

Dir.foreach("#{Chef::Config[:file_cache_path]}/cookbooks/my_workstation/files/cursors") do |cursor|
  next if cursor == '.' or cursor == '..'

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

template "#{ENV['HOME']}/.config/autostart/btsync.desktop" do
  source '.config/autostart/btsync.desktop.erb'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0664'
end

#-----------------------------------------------------------------------------------------------------------------------
# General configuration changes

%W(
  #{ENV['HOME']}/.config/variety/
).each do |dir|
  directory dir do
    owner CURRENT_USER
    group CURRENT_USER
    recursive true
    action :create
  end
end

# "Variety" wallpaper changer util's config.
template "#{ENV['HOME']}/.config/variety/variety.conf" do
  source '.config/variety/variety.conf.erb'
  owner CURRENT_USER
  group CURRENT_USER
  mode '0644'
  variables(:custom_folder => "#{ENV['HOME']}/Pictures")
  not_if "test -e #{ENV['HOME']}/.config/variety/variety.conf"
end

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
