# chef_workstation
A vagrant box that makes it super duper easy to get up and running developing cookbooks with chef.

Installs an ubuntu 12.02 box with:
- chefdk
- docker
- nano text editor
- git
- ssh forwarding
- squid proxy cache
- SSH agent forwarding
- knife.rb
- Works with VirtualBox, Parallels, Hyper-V and VMWare
- Secret energizing ingredient guaranteed to infuze your soul with the spirit of automation!!

This box is an adaptation of the vagrant box we use at CenturyLink cloud developed by Tim Shakarian, Drew Miller and myself. I have updated it and removed some of our CenturyLink specific plumbing to try and make it universally usable.

> :warning: If using test-kitchen for testing cookbooks, this box is ideally suited to using the `kitchen-docker` driver or your favorite cloud driver. It is not intended for use with the `kitchen-vagrant` driver using a local hypervisor (VMWare Workstation, VirtualBox, Hyper-V, etc.) since this box itself is typically run in a local hypervisor.

## Prerequisites

### Install vagrant
```
wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb"
sudo dpkg -i "vagrant_1.7.2_x86_64.deb"
```
### Install Vagrant-omnibus
`$ vagrant plugin install vagrant-omnibus`

### Install Vagrant-cachier (optional)

> :warning: Vagrant-cachier is not supported on Windows at this time.

`$ vagrant plugin install vagrant-cachier`

### Install Vagrant-vbguest (VirtualBox only)

`$ vagrant plugin install vagrant-vbguest`

## Chef keys and knife config
 - The included `.chef/knife.rb` defaults to using the name of the currently logged in user.
 - The `chef_server_url` must be populated with your chef server address. By default it has the url of the hosted chef server, but you will need to append your organization.
 - There should be a `.pem` file in the `.chef` folder with the same name as the chef user.

 This .chef folder is included in the `.gitignore` and the generated knife.rb is copied there if there is no other `knife.rb` during the workstation provisioning. You can feel free to copy keys and anything else you want to keep from being saved to source control.

## Configuring the box

There are two places where you can configure how the box is built

### Vagrantfile

The vagrantfile sends some initial attributes to the workstation cookbook based on some properties in the box:

```
user = ( ENV['USER'] || ENV['USERNAME'] ).downcase
sync_folder = '/chef-repo'

chef.json = {
  "chef_workstation" => {
    "root_folder" => sync_folder,
    "vagrant_version" => Vagrant::VERSION,
    "chef_user" => user
  }
}
```
`chef_user` - The chef server userame you log in with
`root_folder` - The name of the folder created that will remain in sync with the root of this repo on the host
`vagrant_version` - The vagrant version installed on the guest. This defaults to the same version on the host and you likely do not want to change this.

You may want to change other settinga in the `Vagrantfile` such as memory (defaults to 1gb), chef version, or adding other synced folders or chef cookbooks to the provisioning.

### chef_workstation cookbook attributes

The best way to override any of these settings is by changing/adding the overrides set in the `Vagrantfile`.

- `default["chef_workstation"]["chef_user"]` - Defaults to the name of the user logged in on the host.
- `default["chef_workstation"]["user"]` - Defaults to 'vagrant'
- `default["chef_workstation"]["group"]` - Defaults to 'vagrant'
- `default['chef_workstation']['chefdk_version']` - Defaults to 0.5.1-1
- `default['chef_workstation']['vagrant_version']` - Defaults to the version on the host
- `default['chef_workstation']['docker_version']` - Defaults to 1.6.0
- `default['chef_workstation']['chef_server']['user']` = "\#{ENV['USERNAME'] || ENV['USER']}"
- `default['chef_workstation']['chef_server']['url']` - The chef server url inserted in the `knife.rb`. Defaults to `https://api.opscode.com/organizations/`
- `default['chef_workstation']['packages']` - Array of packages installed via `apt-get`. This defaults to the following list:

```
[
  'apt-transport-https',
  'apparmor',
  'build-essential',
  'git',
  'iptables-persistent',
  'iputils-ping',
  'linux-headers-generic-lts-trusty',
  'linux-image-generic-lts-trusty',
  "lxc-docker-#{node["chef_workstation"]["docker_version"]}",
  'nano',
  'squid3'
]
```
- `default['chef_workstation']['gems']` - Array of gems to include in the root `Gemfile`. This defaults to the following list:
```
[
  'chef-vault',
  'kitchen-docker',
  'kitchen-vagrant',
  'vagrant-wrapper',
  'kitchen-nodes'
]
```
The cookbook will `bundle install` these into the user gem store so gems added to `files/default/bundler/Gemfile` can be used without needing to use `bundle exec`.

## Adding cookbooks to develop with your box

The main reason for using this box is to create an environment ideal for testing cookbook development especially with docker. You can add cookbooks to the cookbook directory either by cloning there or simply copying them,but cloning is likely preferable. This can be done either on the host of the guest and the cookbooks will sync accross in real time so that you can use your favorite text editor or IDE.

The cookbook directory is included in the `.gitignore` file so they will not be added to this repo.

If you use SSH to authenticate to github or another git provider, you should be able to execute git commands on the vagrant box and auhenticate as you would on the host since ssh agent forwarding is enabled.

## Using this box

- Ensure you have the required prerequisites installed, listed above
- Change the `chef_server` attributes to the correct values for your server if you plan to issue knife commands against a chef server
- If you are using a hypervisor other than VirtualBox, set your `VAGRANT_DEFAULT_PROVIDER` environment variable to the vagrant provider you plan to use
- Create the box by running `vagrant up`
- Log into the box with `vagrant ssh`
- Accept the immediate infusion of automation energy as it penetrates mind, body and spirit (allow as much time as desired)
- Now you can run kitchen tests with docker, issue knife commands against your chef server (if applicable), run chefspecs, etc.

## Rake tasks

This workstation comes with a top level `Rakefile` thatdefines these tasks:

### foodcritic

This can run foodcritic tasks for all cookbooks:

```
rake foodcritic
```

Or it can just run them for a specific cookbook:

```
rake foodcritic[my_cookbook]
```

### chefspec

This can run chefspec tasks for all cookbooks:

```
rake chefspec
```

Or it can just run them for a specific cookbook:

```
rake chefspec[my_cookbook]
```

### kitchen

Runs `kitchen test -c --destroy=always` for a specific cookbook.

If kitchen tests need to be "orchestrated" in a particular order, you can define your own `Rakefile` in your cookbook. The `kitchen` task will find your custom task as long as the following conditions are met:

- The custom task must be named `integration`
- The task must reside inside a namespace with the same name as your cookbook

Lets say you have a `chef_server` cookbook that requires kitchen suites to be run in a specific order. Here is how its `Rakefile` would look to be "discovered" by the chef_workstation:

```
require 'kitchen/rake_tasks'

namespace "chef_server" do
  Dir.chdir File.dirname(__FILE__) do
    Kitchen::RakeTasks.new
  end
  
  desc "run integration tests"
  task :integration do
    system('sudo -E kitchen destroy')
    system('sudo -E kitchen converge tear-down-ubuntu-1204')
    system('sudo -E kitchen converge chef-server-ubuntu-1204') or exit!(1)
    system('sudo -E kitchen converge organization-ubuntu-1204 -l debug') or exit!(1)
    system('sudo -E kitchen verify chef-server-ubuntu-1204') or exit!(1)
    system('sudo -E kitchen verify organization-ubuntu-1204') or exit!(1)
    system('sudo -E kitchen converge tear-down-ubuntu-1204')
    system('sudo -E kitchen destroy')
  end
end
```

## Other special features

### Proxy caching

Unless you are on a windows host and if you have vagrant-cachier installed (see prerequisites), all deb packages and gems installed on the box are cached on the host. This means you can destroy your box and rebuild it and all builds after the first one will be much faster.

### SSH agent forwarding

All SSH keys on the host used to authenticate to machines you regularly use will be acceible from the vagrant box as if you were on the host.

## Why install vagrant on the box?

This is a bit of a clumsy work around for running test-kitchen tests. If you are running kitchen tests even if not using the vagrant driver but the `.kitchen.yml` has suites using the vagrant driver, test-kitchen will raise an error stating it cant find vagrant. So to suppress his error, we install vagrant on the box even though we do not use it.
