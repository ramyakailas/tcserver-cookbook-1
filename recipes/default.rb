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

begin
  tcserver = Mixlib::ShellOut.new(
    '/opt/vmware/vfabric-tc-server-standard/myserver/bin/tcruntime-ctl.sh status',
    :user => 'root').run_command.stdout
rescue
  tcserver = ''
end

tcserver_instance node['tcserver']['server_name'] do
  action :create
  not_if { ::Dir.exist?('/opt/vmware/vfabric-tc-server-standard/myserver/bin/') }
end


cookbook_file "#{node['tcserver']['warpath']}/CrunchifyTutorial-0.0.1-SNAPSHOT.war" do
  source 'CrunchifyTutorial-0.0.1-SNAPSHOT.war'
  owner 'root'
  group 'root'
  mode 00644
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
