default["chef_workstation"]["chef_user"] = ENV['USER']
default["chef_workstation"]["user"] = 'vagrant'
default["chef_workstation"]["group"] = 'vagrant'
default['chef_workstation']['chefdk_version'] = '0.10.0-1'
default['chef_workstation']['vagrant_version'] = '1.7.4'
default['chef_workstation']['docker_version'] = '1.6.0'
default['chef_workstation']['chef_server']['user'] = "\#{ENV['USERNAME'] || ENV['USER']}"
default['chef_workstation']['chef_server']['url'] = "https://api.opscode.com/organizations/"
default['chef_workstation']['packages'] = [
  'apparmor',
  'build-essential',
  'curl',
  'git',
  'iptables-persistent',
  'iputils-ping',
  'linux-headers-generic-lts-trusty',
  'linux-image-generic-lts-trusty',
  "lxc-docker-#{node["chef_workstation"]["docker_version"]}",
  'nano',
  'squid3'
]
default['chef_workstation']['gems'] = [
  'chef-vault',
  'kitchen-docker',
  'kitchen-vagrant',
  'vagrant-wrapper',
  'kitchen-nodes',
  'pry-byebug'
]
