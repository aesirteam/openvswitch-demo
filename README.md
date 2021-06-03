# openvswitch-demo
### 实验目标  
a. 宿主机单网口上网(负责ovs数据转发及nat转换)  
b. 通过netns实现虚拟机vm重复子网段隔离(模拟多租户模型)  
c. 通过dnsmasq实现各子网段的动态地址分配及域名解析  
d. 暂不考虑vxlan实现跨主机组网  

### 网络拓扑  
![ovs-demo](https://user-images.githubusercontent.com/5821532/120485901-1e692100-c3e7-11eb-9150-d6c8bea79ed8.png)

# Vagrant  
### 软件安装  
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -  
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"  
sudo apt-get update && sudo apt-get install qemu-kvm libvirt-daemon-system virt-install vagrant  
### 插件安装  
vagrant plugin install vagrant-libvirt vagrant-mutate vagrant-rekey-ssh  
### 镜像安装  
vagrant box add centos/7
### 启动虚拟机  
vagrant up  
### 释放虚拟机  
vagrant destroy -f  
