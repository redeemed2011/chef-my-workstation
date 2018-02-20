#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop
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
# Run Recipes

# Ubuntu specific.
include_recipe 'my_workstation::ubuntu_default_desktop'

#-----------------------------------------------------------------------------------------------------------------------
# Manage General Packages

if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host' then
  # Add user to the vboxusers (virtualbox) group.
  # TODO: fix this so that it doesn't add root but rather the actual user.
  group 'vboxusers' do
    action :create
    members %W(#{CURRENT_USER})
  end

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
# Application Shortcuts

cookbook_file '/usr/share/applications/syncthing.desktop' do
  source 'applications/syncthing.desktop'
  owner 'root'
  group 'root'
  mode '0644'
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
# General configuration changes

# This is not idempotent.
bash 'fix perms on home' do
  # user CURRENT_USER
  code <<-EOH
    find #{ENV['HOME']} -user root -exec chown --no-dereference #{CURRENT_USER} {} +;
    find #{ENV['HOME']} -group root -exec chgrp --no-dereference #{CURRENT_USER} {} +;
  EOH
end
