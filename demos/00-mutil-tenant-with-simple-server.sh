#!/bin/sh

gen_dnsmasq_config() {
iface=$1
path=/var/lib/libvirt/dnsmasq/$iface.conf
cat << EOF > $path
strict-order
pid-file=/var/run/libvirt/network/$name.pid
except-interface=lo
bind-dynamic
interface=$iface
dhcp-range=192.168.0.1,192.168.0.99
dhcp-option=3,192.168.0.1
dhcp-no-override
dhcp-authoritative
dhcp-lease-max=65534
dhcp-hostsfile=/var/lib/libvirt/dnsmasq/$iface.hostsfile
addn-hosts=/var/lib/libvirt/dnsmasq/$iface.addnhosts
EOF
echo $path
}

for n in "85588576d" "1ba3ab31"; do
  if [ ! -f /var/run/netns/ns-$n ]; then
    # 创建网络命名空间，实现租户网络隔离 
    ip netns add ns-$n
  fi
  
  # 创建租户内部DHCP服务，为vm提供动态地址分配
  if [ ! -f /proc/*/net/vlan/qdhcp-$n ]; then
     # 创建br-int网桥vlan设备并加入netns
    let vid++
    ip link add link br-int name qdhcp-$n netns ns-$n type vlan id $vid
         
    # qdhcp-XXX设置ip地址后启动dhcp服务
    ip netns exec ns-$n ip addr add 192.168.0.1/24 dev qdhcp-$n
    ip netns exec ns-$n ip link set lo up
    ip netns exec ns-$n ip link set qdhcp-$n up
    ip netns exec ns-$n /sbin/dnsmasq --conf-file=$(gen_dnsmasq_config  qdhcp-$n) --leasefile-ro
  fi
  
  # 创建租户内部与外部的网络连通，为vm提供nat转发服务
  if [ ! -d /sys/devices/virtual/net/veth-$n ]; then
    # 创建veth pair设备并加入netns
    ip link add eth1-$n  netns ns-$n type veth peer name veth-$n
    ip netns exec ns-$n ip link set eth1-$n name eth1 up
    ip link set veth-$n up

    # veth-XXX端加入ovs的br-ex网桥 
    ovs-vsctl add-port br-ex veth-$n
    
    # eth1-XXX端通过上游dhcp服务获取动态地址，实现外网连通
    ip netns exec ns-$n /sbin/dhclient -q --no-pid -lf /var/lib/dhclient/dhclient--qbr-$n.lease  eth1

    # 开启网络命名空间下IP转发功能
    ip netns exec ns-$n sysctl -w net.ipv4.ip_forward=1 > /dev/null

    # 开启内部地址到外部的路由转发规则
    ip netns exec ns-$n iptables -t nat -F    
    ip netns exec ns-$n iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -d 224.0.0.0/24 -j RETURN
    ip netns exec ns-$n iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -d 255.255.255.255 -j RETURN
    ip netns exec ns-$n iptables -t nat -A POSTROUTING -s 192.168.0.0/24 ! -d 192.168.0.0/24 -j MASQUERADE
  fi
done
