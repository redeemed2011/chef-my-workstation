#
# Cookbook Name:: my_workstation
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# FEDORA ONLY!
return unless platform?('fedora') 

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

#...

#-----------------------------------------------------------------------------------------------------------------------
# Add Repositories

package "RPM Fusion Repos" do 
  source "http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-#{platform_version}.noarch.rpm";
  provider Chef::Provider::Package::Rpm
  ignore_failure true
end

package "RPM Fusion Repos" do 
  source "http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-#{platform_version}.noarch.rpm";
  provider Chef::Provider::Package::Rpm
  ignore_failure true
end

package "CERT Forensics Repo" do
  source "https://forensics.cert.org/cert-forensics-tools-release-#{platform_version}.rpm"
  provider Chef::Provider::Package::Rpm
end


#-----------------------------------------------------------------------------------------------------------------------
# Manage General Packages

# Desirables.
%w(
  git
  htop
  iotop
  ShellCheck
  kernel-devel
  powerline powerline-docs
  python3 python3-setuptools
  p7zip
).each do |pkg|
  # apt-fast
  # arc-theme ceti-2-theme vertex-theme
  package pkg do
    action :install
  end
end
