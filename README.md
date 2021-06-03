# openvswitch-demo
### 实验目标  
a. 宿主机单网口上网(负责ovs数据转发及nat转换)  
b. 通过netns实现虚拟机vm重复子网段隔离(模拟多租户模型)  
c. 通过dnsmasq实现各子网段的动态地址分配及域名解析  
d. 暂不考虑vxlan实现跨主机组网  

### 网络拓扑  
![ovs-demo](https://user-images.githubusercontent.com/5821532/120485901-1e692100-c3e7-11eb-9150-d6c8bea79ed8.png)

### 单机环境
- **libvirt安装**    
```
sudo apt-get install qemu-kvm libvirt-daemon-system virt-install  
sudo sed -i 's/#user =/user =/g;s/#group =/group =/g' /etc/libvirt/qemu.conf  
sudo systemctl start libvirtd  
sudo systemctl enable libvirtd
```    
- **删除默认linux bridge**
```
virsh net-destroy default  
virsh net-undefine default  
```
- **openvswitch安装**
```
sudo apt-get install openvswitch-switch
```
- **创建br-int网桥**
```
ovs-vsctl add-br br-int  
```
### 多主机模拟  
- **vagrant安装**
```  
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -  
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"  
sudo apt-get update && sudo apt-get install vagrant  
```
- **plugin安装**
```  
vagrant plugin install vagrant-libvirt vagrant-mutate vagrant-rekey-ssh  
```
- **box安装**  
```
vagrant box add centos/7 --provider libvirt
```
- **启动虚拟机**
```  
vagrant up
```
- **连接虚拟机**
```
virsh console server1 (控制台)
or
ssh vagrant@虚拟机IP (远程终端)
默认密码: vagrant
```
- **释放虚拟机**
```  
vagrant destroy -f
```
