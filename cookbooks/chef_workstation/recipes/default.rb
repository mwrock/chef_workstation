bash "apt-get keyserver" do
  code "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9"
end

bash 'docker sources' do
  code <<-EOS
    sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
  EOS
end

execute "update apt-get" do
  command "apt-get update"
end

package node['chef_workstation']['chef_server']['packages']

directory '/var/cache/wget'

dk_file = "chefdk_#{node['chef_workstation']['chefdk_version']}_amd64.deb"
dk_url = "https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/#{dk_file}"
vagrant_file = "vagrant_#{node['chef_workstation']['vagrant_version']}_x86_64.deb"
vagrant_url = "https://dl.bintray.com/mitchellh/vagrant/#{vagrant_file}"

{dk_file => dk_url, vagrant_file => vagrant_url}.each do |k,v|
  cache_file = File.join("/var/cache/wget", k)
  remote_file cache_file do
    source v
    not_if { ::File.exists?(cache_file) }
  end
  dpkg_package cache_file
end

execute "su - #{node["chef_workstation"]["user"]} -c 'eval \"$(chef shell-init bash)\"'"
execute "su - #{node["chef_workstation"]["user"]} -c 'vagrant plugin install vagrant-winrm'"

%w(Gemfile Gemfile.lock).each do |file|
  cookbook_file File.join(node["chef_workstation"]["root_folder"], file) do
    source "bundler/#{file}"
    owner node['chef_workstation']['user']
    group node['chef_workstation']['group']
  end
end

execute 'chef exec bundle install' do
  cwd node['chef_workstation']['root_folder']
  user node['chef_workstation']['user']
  environment ({
    'HOME' => "/home/#{node['chef_workstation']['user']}",
    'USER' => node['chef_workstation']['user']
  })
  not_if 'bundle check'
end

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

bash "save iptables and append load command to rc.local" do
  code "iptables-save > /etc/iptables/rules.v4"
end

directory '/chef-repo/.chef' 
template '/chef-repo/.chef/knife.rb' do
  source '.chef/knife.rb.erb'
  variables({
    :chef_server_user => node['chef_workstation']['chef_server']['user'],
    :chef_server_url => node['chef_workstation']['chef_server']['url']    
  })
  action :create_if_missing
end

cookbook_file "/home/#{node["chef_workstation"]["user"]}/art.txt" do
  source "home/art.txt"
end
