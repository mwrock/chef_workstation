node.default["chef_workstation"]["bundler_path"] = "/chef-repo"
include_recipe "chef_workstation::root"
include_recipe "chef_workstation::developer"
