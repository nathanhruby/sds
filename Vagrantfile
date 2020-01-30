# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # hostmanger plugin 
  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  config.hostmanager.include_offline = true

  # vbguest plugin - base box does this for us, so skip it
  config.vbguest.auto_update = false

  # Create / Upgrade this box with 'cd base-box && ./build.sh'
  # It is a repackaged Vagrant machine, add any global host changes
  # to the Vagrantfile there
  config.vm.box = "sds-base"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 3096
    vb.linked_clone = true
  end

  # we install these in the base box, but start them here so that we will be
  # sure all our interfaces will up up and running, since vagrant futzes with
  # them after boot
  config.vm.provision "shell", inline: <<-SHELL
    for i in consul nomad ; do 
      sudo systemctl enable ${i}.service
      sudo systemctl start ${i}.service
      # years later, yes this still makes a difference :(
      # sdc is the extra disk we add, we make it faster for portworx
      sudo echo deadline > /sys/block/sdc/queue/scheduler || true
    done
  SHELL


  (1..3).each do |num|
    config.vm.define "box-#{num}" do |box|
      add_disk = ".vagrant/box-#{num}-add-disk.vdi"
      box.vm.hostname = "box-#{num}.sds.example.com"
      box.vm.network "private_network", ip: "192.168.78.#{num + 10}"
      box.vm.provider "virtualbox" do |bvb|
        # give even numbered machines extra ram if you have big jobs
        # if (num % 2 == 0)
        #   bvb.memory = 4096
        # end
        unless File.exist?(add_disk)
          bvb.customize ['createmedium', '--filename', add_disk, '--variant', 'Fixed', '--size', 20 * 1024]
        end
        bvb.customize ['storageattach', :id, '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--nonrotational', 'on', '--discard', 'on', '--medium', add_disk]
      end
    end
  end

end