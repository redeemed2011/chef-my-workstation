include_recipe 'chef-sugar::default'

log "node['virtualization'] is '#{node.deep_fetch(:virtualization)}'"

log "node['virtualization']['system'] is '#{node.deep_fetch(:virtualization, :system)}'"
