# -*- mode: ruby -*-
# vi: set ft=ruby :

# NOTE: custom template.
require_relative 'ruby/custom_templates'

Vagrant.configure(2) do |config|
  # used base box's url. It is necessary to convert the format libvirt.
  #  cf. http://www.vagrantbox.es/
  # config.vm.box_url = "https://github.com/kraksoft/vagrant-box-ubuntu/releases/download/14.04/ubuntu-14.04-amd64.box"

  HOST_NAME1 = "host01"
  BOX_NAME = "host01"
  VAGRANT_DIR = "/vagrant"

  config.vm.box = BOX_NAME

  # libvirt
  config.vm.provider :libvirt do |libvirt|
    libvirt.storage_pool_name = "local"
    libvirt.cpus = 4
    libvirt.memory = 4096
    libvirt.nic_model_type = "e1000"
    libvirt.nested = true
    libvirt.cpu_mode = "custom"
  end
end
