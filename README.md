# chef_workstation

Installs an ubuntu 12.02 bix with:
- chefdk
- docker
- latest test-kitchen

## Prerequisites

### Install Vagrant-omnibus
`$ vagrant plugin install vagrant-omnibus`

### Install Vagrant-cachier (optional)

> :warning: Vagrant-cachier is not supported on Windows at this time.

`$ vagrant plugin install vagrant-cachier`

## Chef keys and knife config
 - The included `.chef/knife.rb` expects the user's chef user to be named the same as the logged in user
 - The `chef_server_url` must be populated with your chef server address
 - There should be a `.pem` file in the `.chef` folder with the same name as the logged in user