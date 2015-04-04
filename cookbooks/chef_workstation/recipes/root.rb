execute "update apt-get" do
  command "apt-get update"
end

%w{iputils-ping build-essential apt-transport-https}.each do |pkg|
  package pkg
end

bash "apt-get keyserver" do
  code "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9"
end

bash "docker sources" do
  code <<-EOS
    sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
  EOS
end

directory "/var/cache/wget"

remote_file "/var/cache/wget/chefdk_0.4.0-1_amd64.deb" do
  source "https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chefdk_0.4.0-1_amd64.deb"
  not_if { ::File.exists?("/var/cache/wget/chefdk_0.4.0-1_amd64.deb") }
end

dpkg_package "/var/cache/wget/chefdk_0.4.0-1_amd64.deb"

package 'git'

directory node["chef_workstation"]["bundler_path"]
%w{Gemfile Gemfile.lock}.each do |file|
  cookbook_file "#{node["chef_workstation"]["bundler_path"]}/#{file}" do
    source "bundler/#{file}"
  end
end

execute "#{node['chef_workstation']['bin_path']}/bundle install --system" do
  cwd node["chef_workstation"]["bundler_path"]
  not_if 'bundle check'
end

package "linux-image-generic-lts-raring"
package "linux-headers-generic-lts-raring"
package "apparmor"

execute "update apt-get again or lxc-docker installation will fail" do
  command "apt-get update"
end

package "lxc-docker-1.2.0"
package 'zip'
