# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  config.hostmanager.include_offline = true

  # Create / Upgrade this box with 'cd base-box && ./build.sh'
  # It is a repackaged Vagrant machine, add any global host changes
  # to the Vagrantfile there
  config.vm.box = "sds-base"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 2048
    vb.linked_clone = true
  end

  (1..3).each do |num|
    config.vm.define "box-#{num}" do |box|
      add_disk = ".vagrant/box-#{num}-add-disk.vdi"
      box.vm.hostname = "box-#{num}.sds.example.com"
      box.vm.network "private_network", ip: "192.168.78.#{num + 10}"
      box.vm.provider "virtualbox" do |bvb|
        unless File.exist?(add_disk)
          bvb.customize ['createmedium', '--filename', add_disk, '--variant', 'Fixed', '--size', 20 * 1024]
        end
        bvb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', add_disk]
      end
    end
  end

end