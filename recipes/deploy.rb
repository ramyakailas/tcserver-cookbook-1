include_recipe 'java'

if platform?('ubuntu')
  include_recipe 'apt::default'
elsif platform?('rhel')
  include_recipe 'yum::default'
end

file_cache_path = node['tcserver']['file_cache_path'] ? node['tcserver']['file_cache_path'] : Chef::Config[:file_cache_path]

remote_file "#{file_cache_path}/#{node['tcserver']['rpm_filename']}" do
  owner 'root'
  group 'root'
  mode '0644'
  source node['tcserver']['rpm_url']
end

package node['tcserver']['rpm_filename'] do
  source "#{file_cache_path}/#{node['tcserver']['rpm_filename']}"
end

begin
  tcserver = Mixlib::ShellOut.new(
    '/opt/vmware/vfabric-tc-server-standard/#{node["tcserver"]["server_name"]/bin/tcruntime-ctl.sh status',
    :user => 'root').run_command.stdout
rescue
  tcserver = ''
end

tcserver_instance node['tcserver']['server_name'] do
  action :create
  not_if { ::Dir.exist?('/opt/vmware/vfabric-tc-server-standard/#{node["tcserver"]["server_name"]}/bin/') }
end

node['tenants'].each do |v|
  artifact_deploy v['name'] do
    version           '2.10'
    artifact_location v['url']
    deploy_to         "#{node['tcserver']['warpath']}/#{v['name']}"
    owner             'root'
    group             'root'
  end
end

tcserver_ctl node['tcserver']['server_name'] do
  action :start
  not_if { tcserver =~ /RUNNING as/ }
end

include_recipe 'ohai'
ohai 'reload_tcserver' do
  plugin 'tcserver'
  action :nothing
end

directory '/etc/chef/ohai_plugins' do
  recursive true
end

cookbook_file '/etc/chef/ohai_plugins/tcserver.rb' do
  source 'plugins/tcserver.rb'
  action :create
  owner 'root'
  group 'root'
  mode 0644
  notifies :reload, 'ohai[reload_tcserver]', :immediately
end
