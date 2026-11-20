# Local test VM for newt_ynh (YunoHost 12 on Debian 12)
#
#   vagrant up                     # creates VM, installs + post-installs YunoHost (~15 min first time)
#   vagrant rsync                  # push package changes into the VM
#   vagrant ssh -c "sudo /vagrant/tests/vagrant/lifecycle.sh"
#
# Optional real Pangolin credentials (otherwise dummy values are used):
#   vagrant ssh -c "sudo EP=https://pangolin.example.ch ID=xxx SECRET=yyy /vagrant/tests/vagrant/lifecycle.sh"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "ynh-test"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: [".git/", ".vagrant/"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "newt_ynh-test"
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision "shell", path: "tests/vagrant/provision.sh"
end
