current_dir = File.dirname(__FILE__)
user = (ENV['CHEF_USER'] || ENV['USERNAME'] || ENV['USER']).downcase
log_level                :info
log_location             STDOUT
node_name                user
client_key               "#{current_dir}/#{node_name}.pem"
validation_client_name   "validator"
validation_key           "#{current_dir}/validator.pem"
chef_server_url          "https://"
cookbook_path            ["#{current_dir}/../cookbooks"]
ssl_verify_mode :verify_none

knife[:editor] = '"/usr/bin/nano"'
