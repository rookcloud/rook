# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion-open-ubuntu-12.04-amd64"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/ubuntu-12.04.3-amd64-vbox.box"

  # Basic port forwarding
  config.vm.network "private_network", ip: "172.18.0.2"

  # Share the entire app
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "..", "/vagrant"

  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/ubuntu-12.04.3-amd64-vmwarefusion.box"
  end

  # Additional Provisioning
  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    
    # Install Docker and bridge-utils, a dependency for Pipework
    pkg_cmd =  %{wget -q -O - https://get.docker.io/gpg | apt-key add -; }
    pkg_cmd << %{echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list; }
    pkg_cmd << %{apt-get update -qq; apt-get install -q -y --force-yes lxc-docker bridge-utils; }

    # Add the Vagrant user to the Docker group
    pkg_cmd << %{usermod -a -G docker vagrant; }

    # Install the pipework tool (by Jérôme Petazzoni - https://github.com/jpetazzo)
    pkg_cmd << %{wget --quiet -P "/home/vagrant" https://raw.github.com/ruphin/pipework/master/pipework; }
    pkg_cmd << %{chmod +x /home/vagrant/pipework; }

    config.vm.provision :shell, :inline => pkg_cmd
  end
end