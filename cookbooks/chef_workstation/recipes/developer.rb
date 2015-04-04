template "/home/#{node["chef_workstation"]["user"]}/.bashrc" do
  source "dot.bashrc"
  owner node["chef_workstation"]["user"]
  group node["chef_workstation"]["group"]
  mode "0755"
end

bash "ssh keygen" do
  not_if { ::File.exists?("/home/#{node["chef_workstation"]["user"]}/.ssh/id_rsa") }
  code <<-EOS
    su - #{node["chef_workstation"]["user"]} -c "ssh-keygen -q -f ~/.ssh/id_rsa -N ''"
    su - #{node["chef_workstation"]["user"]} -c "chmod 700 ~/.ssh/id_rsa*;"
  EOS
end

package "squid3"

cookbook_file "/etc/squid3/squid.conf" do
  source "squid/squid.conf"
end

service "squid3" do
  supports :restart => true
  action [ :restart ]
end

bash "configure iptables PREROUTING to route all HTTP through squid3" do
  code "iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3128"
  not_if "iptables -t nat -C PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3128"
end

bash "configure iptables OUTPUT to allow squid3 access to HTTP" do
  code "iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner proxy --dport 80 -j REDIRECT --to-port 3128"
  not_if "iptables -t nat -C OUTPUT -p tcp -m owner ! --uid-owner proxy --dport 80 -j REDIRECT --to-port 3128"
end

package "iptables-persistent"

bash "save iptables and append load command to rc.local" do
  code "iptables-save > /etc/iptables/rules.v4"
end

cookbook_file "/home/#{node["chef_workstation"]["user"]}/art.txt" do
  source "home/art.txt"
end
