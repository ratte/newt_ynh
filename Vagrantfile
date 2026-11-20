# Local test VM for newt_ynh (YunoHost 13 beta on Debian 13 "trixie")
#
#   vagrant up                     # creates VM, installs + post-installs YunoHost (~15 min first time)
#   vagrant rsync                  # push package changes into the VM
#   vagrant ssh -c "sudo /vagrant/tests/vagrant/lifecycle.sh"
#
# Optional real Pangolin credentials (otherwise dummy values are used):
#   vagrant ssh -c "sudo EP=https://pangolin.example.ch ID=xxx SECRET=yyy /vagrant/tests/vagrant/lifecycle.sh"

Vagrant.configure("2") do |config|
  # debian/trixie64 only ships a libvirt box, so use Bento for VirtualBox
  config.vm.box = "bento/debian-13"
  config.vm.hostname = "ynh-test"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: [".git/", ".vagrant/"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "newt_ynh-test"
    vb.memory = 2048
    vb.cpus = 2
  end

  # Reboot afterwards so the kernel upgraded by the YunoHost installer is
  # actually running (the box ships an old, vulnerable kernel).
  config.vm.provision "shell", path: "tests/vagrant/provision.sh", reboot: true
end
