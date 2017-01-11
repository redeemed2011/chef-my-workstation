#
# Cookbook Name:: my_workstation
# Recipe:: default
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

case platform_family
when 'debian'
  include_recipe 'ubuntu_default'
when 'fedora'
  include_recipe 'fedora_default'
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

python_package 'ps_mem' do
  # version '1.0.0'
end

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

cookbook_file "/etc/profile.d/powerline.sh" do
  source 'profile.d/powerline.sh'
  owner 'root'
  group 'root'
  mode '0644'
end

#-----------------------------------------------------------------------------------------------------------------------
# Snapper related.
# https://wiki.archlinux.org/index.php/Snapper

# printf "\n\nEnable Snapper for snapshots.\n"
# sudo systemctl start snapper-timeline.timer snapper-cleanup.timer
# sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer
