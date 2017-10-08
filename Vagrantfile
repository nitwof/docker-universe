# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'centos/7'

  # config.vm.network "forwarded_port", guest: 3000, host: 3000

  config.vm.synced_folder '.', '/vagrant'

  config.vbguest.auto_update = true
  # config.vbguest.installer_arguments = %w[--nox11]
  config.vm.provider 'virtualbox' do |vb|
    vb.gui = false
    vb.cpus = 1
    vb.memory = '512'
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
  end
  config.ssh.forward_agent = true

  config.vm.provision 'shell', inline: <<-SHELL
    VUSER=vagrant

    yum update
    yum upgrade -y
    yum install -y git gcc g++ make vim curl wget kernel-devel-$(uname -r)

    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce
    groupadd docker
    usermod -aG docker $VUSER
    systemctl enable docker

    echo '{' > /etc/docker/daemon.json
    echo '  "insecure-registries" : ["192.168.35.1:5000"]' >> /etc/docker/daemon.json
    echo '}' >> /etc/docker/daemon.json
    systemctl restart docker

    curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  SHELL

  config.vm.define 'node1' do |node1|
    node1.vm.network 'private_network', ip: '192.168.35.11'
  end

  config.vm.define 'node2' do |node2|
    node2.vm.network 'private_network', ip: '192.168.35.12'
  end
end
