# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'

  config.vm.provider 'virtualbox' do |vb|
    vb.gui = false
    vb.memory = '512'
  end

  config.vm.provision 'shell', inline: <<-SHELL
    apt-get update
    apt-get install -y curl jq apt-transport-https ca-certificates software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce

    echo '{' > /etc/docker/daemon.json
    echo '  "insecure-registries" : ["192.168.33.1:5000"]' >> /etc/docker/daemon.json
    echo '}' >> /etc/docker/daemon.json
    systemctl restart docker
    sudo usermod -aG docker ubuntu
  SHELL

  config.vm.define 'node1' do |node|
    node.vm.hostname = 'node1'
    node.vm.network 'private_network', ip: '192.168.33.11'
  end

  config.vm.define 'node2' do |node|
    node.vm.hostname = 'node2'
    node.vm.network 'private_network', ip: '192.168.33.12'
  end

  config.vm.define 'node3' do |node|
    node.vm.hostname = 'node3'
    node.vm.network 'private_network', ip: '192.168.33.13'
  end
end
