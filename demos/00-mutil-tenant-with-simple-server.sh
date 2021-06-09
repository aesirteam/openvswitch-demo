#!/bin/sh

ovs-vsctl br-exists br-int
if [ $? == 2 ]; then
    ovs-vsctl add-br br-int -- set int br-int type=internal
fi

for n in "85588576d" "1ba3ab31"; do
  if [ ! -f /var/run/netns/ns-$n ]; then
    # 创建网络命名空间，实现租户网络隔离 
    ip netns add ns-$n
  fi
  
  # 创建租户内部DHCP服务，为vm提供动态地址分配
  if [ ! -d /sys/devices/virtual/net/qvo$n-0 ]; then 
    # 创建veth pair设备并加入netns
    ip link add veth$n-0 type veth peer name qvo$n-0
    ip link set veth$n-0 netns ns-$n name eth0
    ip netns exec ns-$n ip link set lo up
    ip netns exec ns-$n ip link set eth0 up
    ip link set qvo$n-0 up 

    # vethXXX-0端设置ip地址后启动dhcp服务
    ip netns exec ns-$n ip addr add 192.168.0.1/24 dev eth0
    ip netns exec ns-$n /sbin/dnsmasq --bind-interfaces --except-interface=lo --interface=eth0 --dhcp-range=192.168.0.1,192.168.0.199 --dhcp-option=3,192.168.0.1

    # qvoXXX-0端加入ovs的br-int网桥 
    let vid++
    ovs-vsctl add-port br-int qvo$n-0 tag=$vid  
  fi
  
  # 创建租户内部与外部的网络连通，为vm提供nat转发服务
  if [ ! -d /sys/devices/virtual/net/qvo$n-1 ]; then
     # 创建veth pair设备并加入netns
    ip link add veth$n-1 type veth peer name qvo$n-1
    ip link set veth$n-1 netns ns-$n name eth1
    ip link set qvo$n-1 up

     # qvoXXX-1端加入ovs的br-ex网桥 
    ovs-vsctl add-port br-ex qvo$n-1
    
    # 开启网络命名空间下IP转发功能
    ip netns exec ns-$n sysctl -w net.ipv4.ip_forward=1 > /dev/null

    # vethXXX-1端通过上游dhcp服务获取动态地址，实现外部网络访问
    ip netns exec ns-$n /sbin/dhclient -q --no-pid -pf /var/run/dhclient-veth$n-1.pid eth1

    # 开启内部地址到外部的路由转发规则
    ip netns exec ns-$n iptables -t nat -F    
    ip netns exec ns-$n iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -d 224.0.0.0/24 -j RETURN
    ip netns exec ns-$n iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -d 255.255.255.255 -j RETURN
    ip netns exec ns-$n iptables -t nat -A POSTROUTING -s 192.168.0.0/24 ! -d 192.168.0.0/24 -o eth1 -j MASQUERADE
  fi
done
