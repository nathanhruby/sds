# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  config.hostmanager.include_offline = true

  config.vm.box = "ubuntu/bionic64"

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

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get -y update
    # sudo apt-get -y upgrade
    sudo apt-get -y install unzip golang-cfssl
  SHELL

  config.vm.provision "docker"

  config.vm.provision "file", source: "consul.service", destination: "/tmp/consul.service"
  config.vm.provision "file", source: "nomad.service", destination: "/tmp/nomad.service"
  config.vm.provision "file", source: "consul.json", destination: "/tmp/consul.json"
  config.vm.provision "file", source: "nomad.json", destination: "/tmp/nomad.json"
  config.vm.provision "shell", inline: <<-SHELL
    declare -A versions
    versions[consul]="1.6.1"
    versions[nomad]="0.10.0-beta1"
    for service in "${!versions[@]}" ; do 
      echo "Installing ${service^}..."
      mkdir /var/lib/${service}
      cd /tmp
      curl -sSL https://releases.hashicorp.com/${service}/${versions[$service]}/${service}_${versions[$service]}_linux_amd64.zip > ${service}.zip
      unzip /tmp/${service}.zip
      sudo install ${service} /usr/bin/${service}
      sudo mkdir -p /etc/${service}.d
      sudo chmod a+w /etc/${service}.d
      sudo mv ${service}.json /etc/${service}.d
      sudo mv ${service}.service /etc/systemd/system/${service}.service
      sudo systemctl enable ${service}.service
      sudo systemctl start ${service}
    done
  SHELL

end