#
# Cookbook Name:: ganglia
# Recipe:: default
#
# Copyright 2011, Heavy Water Software Inc.
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
#

case node[:platform]
  when "ubuntu", "debian"
    package "ganglia-monitor"
  when "redhat", "centos", "fedora"
    include_recipe "ganglia::source"

    execute "copy ganglia-monitor init script" do
      command "cp " +
                  "/usr/src/ganglia-#{node[:ganglia][:version]}/gmond/gmond.init " +
                  "/etc/init.d/ganglia-monitor"
      not_if "test -f /etc/init.d/ganglia-monitor"
    end

    user "ganglia"
end

directory "/etc/ganglia"

#enable python modules
if node.ganglia.enable_python

  directory "/etc/ganglia/conf.d" do
    owner 'ganglia'
  end

  directory "/usr/lib/ganglia/python_modules" do
  end

  cookbook_file '/etc/ganglia/conf.d/modpython.conf' do
    source 'modpython.conf'
    owner 'ganglia'
  end
end

service "ganglia-monitor" do
  pattern "gmond"
  supports :restart => true
  action :enable
end


if node[:ganglia][:mode] == 'unicast'

  gmonheads = search(:node, "role:gmonhead").map { |node| node.ipaddress }

  #Read the README to learn how and why to set this up in roles, not in recipes or nodes themselves
  send_port = node['ganglia']['port'] rescue 8649
  cluster = node['ganglia']['cluster'] rescue 'default'

  template "/etc/ganglia/gmond.conf" do
    source "gmond.conf.erb"
    variables :mode => node.ganglia.mode,
              :cluster_name => cluster,
              :gmonheads => gmonheads,
              :send_port => send_port,
              :deaf => 'yes',
              :send_metadata_interval => 60
    notifies :restart, resources(:service => 'ganglia-monitor')
  end


else

  #do multicast by default, default configuration is multicast
  template "/etc/ganglia/gmond.conf" do
    source "gmond.conf.erb"
    variables :mode => 'multicast',
              :cluster_name => node[:ganglia][:cluster_name]
    notifies :restart, resources(:service => 'ganglia-monitor')
  end

end
