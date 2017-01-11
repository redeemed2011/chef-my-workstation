#
# Cookbook Name:: my_workstation
# Recipe:: default_desktop_personal
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

apt_repository 'insync' do
  uri 'http://apt.insynchq.com/ubuntu'
  distribution node.deep_fetch(:lsb, :codename)
  components %w(non-free contrib)
  key 'https://d2t3ff60b2tol4.cloudfront.net/services@insynchq.com.gpg.key'
end

apt_repository 'ubuntu-wine' do
  uri 'ppa:ubuntu-wine/ppa'
  distribution node.deep_fetch(:lsb, :codename)
  components %w(main)
  not_if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host'
end

package "Steam repo" do 
  source 'http://negativo17.org/repos/fedora-steam.repo'
  provider Chef::Provider::Package::Rpm
  ignore_failure true
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
).each do |pkg|
  # steam
  package pkg do
    action :install
  end
end

# Is chef running in a baremetal system?
if node.deep_fetch(:virtualization, :system) == 'host' || node.deep_fetch(:virtualization, :role) == 'host' || node.deep_fetch(:hostnamectl, :virtualization) == 'host' then
  %w(
    playonlinux wine winetricks
  ).each do |pkg|
    package pkg do
      action :install
    end
  end

  bash 'Install Steam' do
    # user CURRENT_USER
    code <<-EOH
      wget -O- https://raw.githubusercontent.com/folkswithhats/fedy/master/plugins/steam.plugin/install.sh | bash -s
    EOH
    unless 'bash 'Install Steam' do
  # user CURRENT_USER
  code <<-EOH
    wget -O- https://raw.githubusercontent.com/folkswithhats/fedy/master/plugins/steam.plugin/install.sh | bash -s
  EOH
  unless 'which steam'
end

'
  end
end

bash 'Install Sublime Text' do
  # user CURRENT_USER
  code <<-EOH
    wget -O- https://raw.githubusercontent.com/folkswithhats/fedy/master/plugins/sublimetext.plugin/install.sh | bash -s
  EOH
  unless 'which subl'
end

bash 'Install Dropbox for Nautilus' do
  # user CURRENT_USER
  code <<-EOH
    wget -O- https://raw.githubusercontent.com/folkswithhats/fedy/master/plugins/dropbox.plugin/install.sh | bash -s
  EOH
  unless 'rpm --quiet --query nautilus-dropbox'
end


