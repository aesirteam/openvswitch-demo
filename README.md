# openvswitch-demo
### 实验目标  
a. 宿主机单网口上网(负责ovs数据转发及nat转换)  
b. 通过netns实现虚拟机vm重复子网段隔离(模拟多租户模型)  
c. 通过dnsmasq实现各子网段的动态地址分配及域名解析  
d. 暂不考虑vxlan实现跨主机组网  
### 物理机Vagrant安装
``` 
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -  
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"  
sudo apt-get update && sudo apt-get install qemu-kvm libvirt-daemon-system vagrant
```
- **plugin安装**
```  
vagrant plugin install vagrant-libvirt vagrant-mutate vagrant-rekey-ssh  
```
- **box安装**  
```
vagrant box add centos/7 --provider libvirt
```
### 单机实验
- **在物理机上创建实验环境**
```  
zhongkui:~$ vagrant up server1
```
- **查看物理机linux bridge状态**
```
zhongkui:~$ sudo virsh net-list
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 br0                  active     yes           yes
 mgmt                 active     yes           yes
```
- **在实验环境中初始化网络拓扑**
```
zhongkui:~$ vagrant ssh server1
[vagrant@server1 ~]$ sudo ./00-mutil-tenant-with-simple-server.sh
```
- **查看实验环境的ovs bridge详情**
![ovs-demo1](https://user-images.githubusercontent.com/5821532/121350274-0b150300-c95d-11eb-95e6-73e1940a0fe5.png)

```
[vagrant@server1 ~]$ sudo ovs-vsctl show
f14f0abb-6128-43ef-97ec-991e45e19e4f
    Bridge br-ex
        Port veth-85588576d
            Interface veth-85588576d
        Port eth1
            Interface eth1
        Port veth-1ba3ab31
            Interface veth-1ba3ab31
        Port br-ex
            Interface br-ex
                type: internal
    Bridge br-int
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.15.0"
```
- **实验环境中创建租户VM实例并桥接至br-int**
```
Usage: ./install_vm.sh [vm名称] [vlan tag编号]
[vagrant@server1 ~]$ sudo ./install_vm.sh vm1 1
[vagrant@server1 ~]$ sudo ./install_vm.sh vm2 2
[vagrant@server1 ~]$ sudo ovs-vsctl show
f14f0abb-6128-43ef-97ec-991e45e19e4f
    Bridge br-ex
        Port veth-85588576d
            Interface veth-85588576d
        Port eth1
            Interface eth1
        Port veth-1ba3ab31
            Interface veth-1ba3ab31
        Port br-ex
            Interface br-ex
                type: internal
    Bridge br-int
        Port br-int
            Interface br-int
                type: internal
        Port vnet0 
            tag: 1
            Interface vnet0
        Port vnet1 
            tag: 2
            Interface vnet1
    ovs_version: "2.15.0"
```
<b>注: 若br-int存在vnet0(tap设备)并且tag=1,则允许从qvo85588576d-0(veth设备)提供的dhcp动态分配地址</b>
- **实验环境中连接VM实例并验证外网连通**
```
[vagrant@server1 ~]$ sudo virsh console vm1
Connected to domain vm1
Escape character is ^]

Welcome to Alpine Linux 3.13
Kernel 5.10.29-0-virt on an x86_64 (/dev/ttyS0)

localhost login: root
Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <http://wiki.alpinelinux.org/>.

You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.

localhost:~#setup-alpine
......
检查路由
vm1:~# ip route show
default via 192.168.0.1 dev eth0  metric 202 
192.168.0.0/24 dev eth0 scope link  src 192.168.0.154

检查外网连通
vm1:~# apk add iperf3
(1/2) Installing iperf3 (3.9-r1)
(2/2) Installing iperf3-openrc (3.9-r1)
Executing busybox-1.32.1-r6.trigger
OK: 9 MiB in 23 packages

```
- **在物理机销毁实验环境**
```  
zhongkui:~$ vagrant destroy server1 -f
```
