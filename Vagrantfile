# -*- mode: ruby -*-
# vi: set ft=ruby :

$servers = [
{
    :name => "server1",
    :vcpu => 2,
    :ram => 2048,
},{
    :name => "server2",
    :vcpu => 2,
    :ram => 2048,
}
]

Vagrant.configure("2") do |config|
    config.vm.box = "centos/7"
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.provision :file, source: "./demos/.", destination: "$HOME/"

    config.vm.provider :libvirt do |lv|
        lv.management_network_name = "mgmt"
        lv.management_network_mode = "none"
        lv.management_network_autostart = true
    end

    config.vm.network :private_network,
        :type => "dhcp",
        :libvirt__network_name => "br0",
        :libvirt__network_address => "10.240.0.0",
        :libvirt__netmask => "255.255.0.0",
        :autostart => true

    $servers.each do |server|
        config.vm.define server[:name] do |srv|
        srv.vm.hostname = server[:name]

        srv.vm.provider :libvirt do |lv|     
            lv.cpus = server[:vcpu]
            lv.memory = server[:ram]
            #lv.storage :file, :size => "4G", :type => "qcow2", :cache => "none"

            lv.default_prefix = ""
            lv.graphics_type = "none"
        end

        srv.vm.provision :shell, inline: <<-SHELL
            sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
            systemctl restart sshd

            yum install -y -q --nogpgcheck qemu-kvm libvirt virt-install python3 net-tools tcpdump
            rm -rf /etc/libvirt/qemu/networks/default.xml
            sed -i 's/^#user/user/;s/^#group/group/' /etc/libvirt/qemu.conf
            systemctl start libvirtd
            systemctl enable libvirtd

            yum localinstall -y -q --nogpgcheck https://github.com/aesirteam/openvswitch-demo/releases/download/v1.0.0/openvswitch-2.15.0-1.x86_64.rpm
            /etc/rc.d/init.d/openvswitch start
            /sbin/chkconfig openvswitch on

            echo -en "
            LANG=en_US.UTF-8
            LC_ALL=" | sed 's/[[:space:]]//g' > /etc/environment

            echo -en "
            ONBOOT=yes
            USERCTL=yes
            PEERDNS=yes
            PERSISTENT_DHCLIENT=1
            DEVICE=br-ex
            DEVICETYPE=ovs
            OVSBOOTPROTO=dhcp
            TYPE=OVSBridge
            OVSDHCPINTERFACES=eth1" | sed 's/[[:space:]]//g' > /etc/sysconfig/network-scripts/ifcfg-br-ex

            echo -en "
            DEVICE=eth1
            DEVICETYPE=ovs
            TYPE=OVSPort
            OVS_BRIDGE=br-ex
            ONBOOT=yes
            BOOTPROTO=none" | sed 's/[[:space:]]//g' > /etc/sysconfig/network-scripts/ifcfg-eth1

            systemctl restart network
        SHELL
    end
  end
end
