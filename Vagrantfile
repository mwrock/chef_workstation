# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
USER = ( ENV['USER'] || ENV['USERNAME'] ).downcase
chef_recipe = ["chef_workstation::default"]
is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.hostname = "chef-workstation"
  config.vm.synced_folder ".", "/chef-repo"
  config.ssh.forward_agent = true

  config.vm.provider "parallels" do |v, override|
    override.vm.box = "parallels/ubuntu-12.04"
    v.update_guest_tools = true
    v.optimize_power_consumption = false
    v.cpus = 2
    v.memory = 2048
  end

  config.vm.provider "hyperv" do |hv|
    hv.ip_address_timeout = 240
  end

  config.vm.provider :virtualbox do |vb, override|
    # NAT settings so network isn't super slow
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.memory = 2048
  end

  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path "."
    chef_recipe.each {|recipe| chef.add_recipe recipe}
    chef.json = {
      "chef_workstation" => {
        "user" => "vagrant",
        "group" => "vagrant",
        "chef_user" => "#{USER}"
      }
    }
  end

  if !Vagrant.has_plugin?("vagrant-omnibus")
    raise Vagrant::Errors::VagrantError.new, "vagrant-omnibus must be installed. Install using \"sudo vagrant plugin install vagrant-omnibus\" before running \"vagrant up\""
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    if (is_windows)
      raise Vagrant::Errors::VagrantError.new, "vagrant-cachier is not supoprted on Windows! Please uninstall using 'vagrant plugin uninstall vagrant-cachier'"
    end

    config.cache.scope = :box
    config.cache.enable :generic, {
      "wget" => { cache_dir: "/var/cache/wget" }
    }
  else
    puts "\e[33mWARNING: vagrant-cachier not installed. Unable to cache dependencies between VM rebuilds.\e[0m"
    puts "\e[33mInstall using: \"sudo vagrant plugin install vagrant-cachier\" before running \"vagrant up\" (unix only). \e[0m"
  end
end
