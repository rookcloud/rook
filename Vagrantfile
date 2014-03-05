# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion-open-ubuntu-12.04-amd64"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/ubuntu-12.04.3-amd64-vbox.box"

  # Assign our VM a private IP address.
  config.vm.network "private_network", ip: "10.15.11.5"

  # Disable sharing synced folders. We don't need any project files inside vagrant.
  config.vm.synced_folder disabled: true

  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/ubuntu-12.04.3-amd64-vmwarefusion.box"
  end

  # Additional Provisioning
  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    
    # Install Docker
    pkg_cmd =  %{wget -q -O - https://get.docker.io/gpg | apt-key add -; }
    pkg_cmd << %{echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list; }
    pkg_cmd << %{apt-get update -qq; apt-get install -q -y --force-yes lxc-docker; }

    # Expose docker on an external VM port so the host can reach it
    pkg_cmd << %{echo 'DOCKER_OPTS="-H tcp://10.15.11.5:4243"' > /etc/default/docker; }
    pkg_cmd << %{sudo service docker restart; }

    # Install the pipework tool (by Jérôme Petazzoni - https://github.com/jpetazzo)
    pkg_cmd << %{wget --quiet -P "/home/vagrant" https://raw.github.com/jpetazzo/pipework/master/pipework; }
    pkg_cmd << %{chmod +x ./home/vagrant/pipework; }

    config.vm.provision :shell, :inline => pkg_cmd
  end
end