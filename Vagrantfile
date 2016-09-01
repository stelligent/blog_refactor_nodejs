Vagrant.configure(2) do |config|
  ENV['VAGRANT_DEFAULT_PROVIDER'] = "virtualbox"

  config.vm.communicator = "ssh"
  config.vm.box = "box-cutter/ubuntu1404-desktop"
  config.vm.network "private_network", ip: "192.168.33.10"
  # config.vm.network "private_network", type: 'dhcp'
  # on the guest, find the IP by: ifconfig | grep "inet addr" (pick eth1)

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.memory = "4096"
    vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
  end

  config.vm.provision "chef_solo" do |chef|
    # Specify the local paths where Chef data is stored
    chef.cookbooks_path = ["./pipelines/cookbooks", "/tmp/blog_refactor_nodejs/vendored-cookbooks"]
    chef.add_recipe "NodeJSApp::default"
    chef.json = {
      "blog_refactor_nodejs" => {
        "folder": "/vagrant",
        "property_str" => "horses",
        "property_num" => 1961,
        "property_bool" => false,
        "property_url" => "https://www.google.com"
      }
    }
    chef.log_level = :debug
    chef.channel = "stable"
    chef.version="12.13.37"
    chef.nodes_path = "/tmp"
  end

  config.vm.provision "shell", privileged: true, inline: <<-SCR2
    forever start --sourceDir /vagrant/app index.js
  SCR2
end
