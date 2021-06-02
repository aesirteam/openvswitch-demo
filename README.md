# openvswitch-demo
### 实验目标  
a. 宿主机单网口上网(负责ovs数据转发及nat转换)  
b. 通过netns实现虚拟机vm重复子网段隔离(模拟多租户模型)  
c. 通过dnsmasq实现各子网段的动态地址分配及域名解析  
d. 暂不考虑vxlan实现跨主机组网  

### 网络拓扑  
![ovs-demo](https://user-images.githubusercontent.com/5821532/120485901-1e692100-c3e7-11eb-9150-d6c8bea79ed8.png)
