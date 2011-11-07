#
# Author:: Gilles Devaux <gilles.devaux@gmail.com>
# Cookbook Name:: ganglia
# Recipe:: gmonhead
#
# Copyright 2011, Formspring.me, Inc
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

#install one gmonhead per role defining ganglia
#this is a bit abrupt as a single machine hosts all the collectors but it's simple
#If you want to modify to allow ad-hoc topologies, please go ahead.

include_recipe 'supervisord'
include_recipe 'ganglia'

#get all the clusters, add the default one
clusters = search(:role, "ganglia:*").map do |role|
  ganglia = role.override_attributes['ganglia']
  {'cluster_name' => ganglia['cluster'], 'receive_port' => ganglia['port']}
end
clusters << {'cluster_name' => 'default', 'receive_port' => 8649}
clusters.uniq!.compact!

#create one config and supervisor per cluster
clusters.each do |cluster|
  template "/etc/ganglia/gmonhead_#{cluster['cluster_name']}.conf" do
    source "gmond.conf.erb"
    variables :mode => 'unicast',
              :cluster_name => cluster['cluster_name'],
              :receive_port => cluster['receive_port']
    owner 'ganglia'
    group 'ganglia'
  end

  supervisord_program "gmonhead_#{cluster['cluster_name']}" do
    command "/usr/sbin/gmond -c /etc/ganglia/gmonhead_#{cluster['cluster_name']}.conf -f"
    user 'ganglia'
  end
end
