case node[:platform]
  when "ubuntu", "debian"
    package "gmetad"
  when "redhat", "centos", "fedora"
    include_recipe "ganglia::source"
    execute "copy gmetad init script" do
      command "cp " +
                  "/usr/src/ganglia-#{node[:ganglia][:version]}/gmetad/gmetad.init " +
                  "/etc/init.d/gmetad"
      not_if "test -f /etc/init.d/gmetad"
    end
end

directory "/var/lib/ganglia/rrds" do
  owner "nobody"
  recursive true
end

if node[:ganglia][:mode] == 'unicast'
  ips = search(:node, "recipes:ganglia").map { |node| node.ipaddress }
  clusters = {'name' => node[:ganglia][:cluster_name], 'hosts' => ips}
else
  #connect gmetad to gmonheads. the gmetad MUST run where all the gmonheads run.
  #if you want to make a more complex topology, please modify.
  clusters = search(:role, "ganglia:*").map do |role|
    ganglia = role.override_attributes['ganglia']
    cluster = ganglia['cluster'] || role.name
    {'name' => cluster, 'hosts' =>["localhost:#{ganglia['port']}"]}
  end
end

template "/etc/ganglia/gmetad.conf" do
  source "gmetad.conf.erb"
  variables(:clusters => clusters,
            :grid_name => node[:ganglia][:gmetad][:grid_name])
  notifies :restart, "service[gmetad]"
end

service "gmetad" do
  supports :restart => true
  action [:enable, :start]
end
