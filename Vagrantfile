# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "lucid64"

  # set up cpu exec cap so that Virtualbox doesn't kill my notebook
  config.vm.customize do |vm|
  	vm.memory_size = 256
  	vm.name = "Percona Toolkit Demos"
  	vm.cpu_execution_cap = 60
  end

  config.vm.provision :shell, :path => "provisioner.sh"

#  config.vm.provision :puppet do |config_puppet|
#    config_puppet.pp_path = "/tmp/vagrant-puppet"
#    config_puppet.manifests_path = "manifests"
#   config_puppet.module_path = "modules"
#    config_puppet.manifest_file = "site.pp"
#    config_puppet.options = "--verbose"
#  end

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/lucid64.box"

end
