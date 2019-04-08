#!/bin/bash

# name: checkNET
# author: fandingjun
# date: 2011-4-13
# modify£ºtanpinchao 2011-8-3

# $1: delay time
# $2: total times

cmd=""
sys_info=$(cat /etc/os-release | grep PRETTY_NAME)
export http_proxy="http://172.19.16.11:3128"
export https_proxy="http://172.19.16.11:3128"

if [ "$(echo $sys_info |grep -E 'UBUNTU|Ubuntu|ubuntu')"x != ""x ]; then
    cmd="apt-get"
elif [ "$(echo $sys_info |grep -E 'cent|CentOS|centos')"x != ""x ]; then
    cmd="yum"
elif [ "$(echo $sys_info |grep -E 'fed|Fedora|fedora')"x != ""x ]; then
    cmd="dnf"
elif [ "$(echo $sys_info |grep -E 'DEB|Deb|deb')"x != ""x ]; then
    cmd="apt-get"
elif [ "$(echo $sys_info |grep -E 'OPENSUSE|OpenSuse|opensuse|openSUSE')"x != ""x ]; then
    cmd="zypper -n"
elif [ "$(echo $sys_info |grep -E 'RedHat|redhat|Redhat')"x != ""x ];then
    cmd="yum"
else
    cmd="apt-get"
fi

$cmd install ethtool pciutils -y 

test_item=$(basename $0)
prelog="${test_item}.prd.log"
curlog="${test_item}.cur.log"
MV=$(which mv)
LSPCI=$(which lspci)
ETHTOOL=$(which ethtool)
IP=$(which ip)
CAT=$(which cat)
DIFF=$(which diff)
TOUCH=$(which touch)
err=0

if [ $# -lt 2 ];then
   echo "${test_item} Fail: Usage: $0 delay total_times" > result.log
  cat result.log
  err=1
   exit $err
fi

if [ -f $curlog ];then
    $MV $curlog $prelog
    $TOUCH $curlog
fi

log (){
    echo [$(date "+%Y-%m-%d %H:%M:%S")] "$@" >> $curlog
    #echo >> $curlog
}

get_link_stat() {
    $ETHTOOL $1 | grep -i "link detected" | awk -F ':' '{print $2}'
}

get_speed(){
    $ETHTOOL $1 | grep -i speed | awk -F ':' '{print $2}'
}

get_pci_info(){
    $LSPCI | grep -i Eth
}

get_up_down_stat(){
    $IP link show $1 | grep UP > /dev/null
    if [ $? -eq 0 ];then
        echo "UP"
    else
        echo "DOWN"
    fi
}

get_nic_name(){
        dmesg -c
    ls /sys/class/net|grep -v -e lo -e sit
}

error (){
    echo -e "${test_item} Fail: $@" > checknet_result.log
    cat checknet_result.log
    exit $err
}
#log "begin: cmdline is '$0 $@'"

count=1
delay=$1
total=$2

if [ $count -gt $total ];then
    pci_count=$($LSPCI|grep -i Eth|wc -l)
    get_pci_info  > net_pci_info

    nic_count=$(get_nic_name | wc -l)

    get_nic_name > net_interface_name

    while read nic_name
    do
        speed=$(get_speed $nic_name)
        log "[begin] $nic_name speed $speed"
        echo $speed > ${nic_name}_speed
        link=$(get_link_stat $nic_name)
        log "[begin] $nic_name linked $link"
        echo $link > ${nic_name}_link
        stat=$(get_up_down_stat $nic_name)
        log "[begin] $nic_name $stat"
        echo $stat > ${nic_name}_stat
    done < net_interface_name
fi

while [ $count -le $total ]
do
    #sleep $delay

    pci_count_1=$($LSPCI|grep -i Eth|wc -l)
    log "[times $count] pci net interface is: $pci_count_1"
    #if [ $pci_count_1 -ne $pci_count ];then
    #		err=2
     #   error "checkNET Fail: old pci dev is $pci_count, now is $pci_count_1"
        #exit 1
   # fi
    log "[times $count] read pci info success"

    get_pci_info  > net_pci_info_1
    #echo "cc" >> net_pci_info_1

    $DIFF -u net_pci_info net_pci_info_1 > net_differ
    if [ $? -ne 0 ];then
    		err=3
        error "net intface info different is:\n$($CAT net_differ)"
    fi 

    nic_count_1=$(get_nic_name | wc -l)

    log "[times $count] nic count is: $nic_count_1"

    #if [ $nic_count_1 -ne $nic_count ];then
    #		err=4
     #   error "checkNET Fail: old nic count is $nic_count, now nic count is $nic_count_1" 
    #fi
    #log "begin nic name is: " $(get_nic_name)

    get_nic_name > net_interface_name_1
    #echo "cc" >> net_interface_name_1
    $DIFF -u net_interface_name net_interface_name_1 > net_name_differ
    if [ $? -ne 0 ];then
    		err=5
        error "net interface name different is:\n$($CAT net_name_differ)"
    fi

    while read nic_name
    do
        speed=$(get_speed $nic_name)
        log "[times $count] $nic_name speed $speed"
        echo $speed > ${nic_name}_speed_1

        #echo "cc" >> ${nic_name}_speed_1
        $DIFF -u ${nic_name}_speed ${nic_name}_speed_1 > speed_differ
        if [ $? -ne 0 ];then
        		err=6
            error "$nic_name 's speed different is:\n$($CAT speed_differ)"
        fi


        link=$(get_link_stat $nic_name)
        log "[times $count] $nic_name linked $link"
        echo $link > ${nic_name}_link_1
        #echo "cc" >> ${nic_name}_link_1
        $DIFF -u ${nic_name}_link ${nic_name}_link_1 > link_differ
        if [ $? -ne 0 ];then
        		err=7
            error "$nic_name 's link stat different is:\n$($CAT link_differ)"
        fi

        stat=$(get_up_down_stat $nic_name)
        log "[times $count] $nic_name $stat"

        echo $stat > ${nic_name}_stat_1
        #echo "cc" >> ${nic_name}_stat_1

        $DIFF -u ${nic_name}_stat ${nic_name}_stat_1 > stat_differ
        if [ $? -ne 0 ];then
        		err=8
            error "$nic_name up/down stat different is:\n$($CAT stat_differ)"
        fi

    done < net_interface_name

    sleep $delay
    let count=count+1
    if [ ! -f checknet_result.log ];then
	echo "${test_item} OK" > checknet_result.log
    fi
    exit $err
done

# echo "${test_item} OK" > checknet_result.log
# cat checknet_result.log
# exit $err
