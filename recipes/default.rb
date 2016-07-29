#
# Cookbook Name:: tcserver
# Recipe:: default
#
# Copyright (C) 2014 Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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

node['instances'].each do |value|
begin
  tcserver = Mixlib::ShellOut.new(
    "/opt/vmware/vfabric-tc-server-standard/#{value['instance_name']}/bin/tcruntime-ctl.sh status",
    :user => 'root').run_command.stdout
rescue
  tcserver = ''
end

tcserver_instance value['instance_name'] do
  action :create
  not_if { ::Dir.exist?("/opt/vmware/vfabric-tc-server-standard/value['instance_name']/bin/") }
end

value['wars'].each do |war_name|
  puts war_name.inspect
artifact_deploy war_name['name'] do
  version           '2.10'
  artifact_location war_name['url']
  deploy_to         "/opt/vmware/vfabric-tc-server-standard/#{value['instance_name']}/webapps/#{war_name['name']}"
  owner             'root'
  group             'root'
end
end

tcserver_ctl value['instance_name'] do
  action :start
  not_if { tcserver =~ /RUNNING as/ }
end
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
