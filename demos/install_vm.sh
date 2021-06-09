#!/bin/sh

vm_id=`uuidgen`
vm_name=${1:-vm-$vm_id}
vm_isofile=/var/lib/libvirt/images/alpine.iso

if [ ! -f $vm_isofile ]; then
    curl -Lo $vm_isofile https://dl-cdn.alpinelinux.org/alpine/v3.13/releases/x86_64/alpine-virt-3.13.5-x86_64.iso
fi

/usr/bin/virt-install \
    --uuid $vm_id \
    --name $vm_name \
    --vcpus 1 \
    --ram 128 \
    --cdrom $vm_isofile \
    --network bridge=br-int,model=virtio,virtualport_type=openvswitch \
    --nodisks \
    --livecd \
    --nographics \
    --noautoconsole \
    --os-type=linux \
    --os-variant=generic

tap_name=`/usr/bin/ovs-vsctl list int | grep -A13 $vm_id | awk -F: 'END {print $2}'`

/usr/bin/ovs-vsctl set port $tap_name tag=${2:-1}
