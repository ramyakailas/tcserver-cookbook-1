#
# Cookbook Name:: tcserver
# Attributes:: default
#
# Copyright (C) 2014 Charles Johnson <charles@getchef.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default['tcserver']['rpm_filename'] = 'vfabric-tc-server-standard-2.9.5-SR1.noarch.rpm'

default['tcserver']['rpm_url'] = "https://dl.dropboxusercontent.com/u/3639771/#{ node['tcserver']['rpm_filename'] }"
default['tcserver']['file_cache_path'] = '/tmp'
default['tcserver']['server_name'] = 'test-instance1'
default['tcserver']['warpath'] = "/opt/vmware/vfabric-tc-server-standard/#{ node['tcserver']['server_name']}/webapps"
