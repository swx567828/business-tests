#!/bin/bash
set -x

#*****************************************************************************
# *用例编号： New_Linux-KVM-022
# *用例功能：多台虚拟机内存加压测试                      
# *作者：dwx588814                            
# *完成时间：                        
# *前置条件：
#    1）配置启动4台4U8G的虚拟机
#    2）虚拟机使用的总内存数不超过HOST总内存的80%,即HOST总内存不能低于40G
# *测试步骤:
#    1)在虚拟机中，通过"cat /proc/meminfo"查看内存信息
#    2)在虚拟机中，根据空闲的内存大小，利用工具"memtester"对内存做加压测试
#*****************************************************************************



#加载公共函数
. ../../../utils/test_case_common.inc
. ../../../utils/error_code.inc
. ../../../utils/sys_info.sh
. ../../../utils/sh-test-lib		

	

#获取脚本名称作为测试用例名称
#test_name=$(basename $0 | sed -e 's/\.sh//')
#创建log目录
#TMPDIR=./logs/temp
#mkdir -p ${TMPDIR}
#存放脚本处理中间状态/值等
#TMPFILE=${TMPDIR}/${test_name}.tmp
#存放每个测试步骤的执行结果
#RESULT_FILE=${TMPDIR}/${test_name}.result
#test_result="pass"

#预置条件
function init_env()
{

#检查结果文件是否存在，创建结果文件：
fn_checkResultFile ${RESULT_FILE}

#root用户执行
if [ `whoami` != 'root' ]
then
    PRINT_LOG "WARN" " You must be root user " 
    return 1
fi


#判断HOST总内存不能低于40G
function preset_conditions()
{

HOST_mem=`free -g |grep 'Mem'|awk '{print $2}'`
if [ "$HOST_mem"x -lt 40 ];then
	PRINT_LOG "WARN" "Host memory too small !"
	return 1
fi

#设置全局变量
path=`pwd`
random_uuid1=`cat /proc/sys/kernel/random/uuid`
random_uuid2=`cat /proc/sys/kernel/random/uuid`
random_uuid3=`cat /proc/sys/kernel/random/uuid`
random_uuid4=`cat /proc/sys/kernel/random/uuid`
random_mac1=`cat /dev/urandom | head -n 10 | md5sum | head -c 2`
random_mac2=`cat /dev/urandom | head -n 10 | md5sum | head -c 2`
random_mac3=`cat /dev/urandom | head -n 10 | md5sum | head -c 2`
random_mac4=`cat /dev/urandom | head -n 10 | md5sum | head -c 2`

#安装依赖包
pkgs="wget expect"
install_deps "${pkgs}"


#安装kvm所需的软件包
case "${distro}" in
	centos)
	cd ~
	pkgs="virt-install libvirt* python2-pip"
	install_deps "${pkgs}"
	print_info $? install_libvirt
	#if [ $? -eq 0 ];then
	    #PRINT_LOG "INFO" "Libvirt was installed successfully"
        #fn_writeResultFile "${RESULT_FILE}" "libvirt_install" "pass"
        #return 0 
    #else
	    #PRINT_LOG "FATAL" "Libvirt installation failed"
        #fn_writeResultFile "${RESULT_FILE}" "libvirt_install" "fail"
        #return 1
    #fi
	
    pip install --ignore-installed --force-reinstall 'requests==2.6.0' urllib3
	cd -
	#下载loder文件
	if [ ! -d /usr/share/AAVMF ];then
		
	mkdir -p /usr/share/AAVMF
	cd /usr/share/AAVMF
	wget ${ci_http_addr}/test_dependents/AAVMF_CODE.fd
	wget ${ci_http_addr}/test_dependents/AAVMF_VARS.fd
	wget ${ci_http_addr}/test_dependents/AAVMF_CODE.verbose.fd
	cd -

	fi
	;;
esac

#初始化libvirtd
sed -i "s/#user = /user = /g" /etc/libvirt/qemu.conf
sed -i "s/#group = /group = /g" /etc/libvirt/qemu.conf
	
#启动libvirt服务
systemctl start libvirtd 
	
#测试libvirt服务是否启动
res=`virsh -c qemu:///system list|grep "Id"|awk '{print $1}'`
if [ "$res"x == "Id"x ];then
	print_info 0 libvirt_start
	#PRINT_LOG "INFO" "Libvirt started successfully"
    #fn_writeResultFile "${RESULT_FILE}" "libvirt_start" "pass"
    #return 0 
else
	print_info 1 libvirt_start
	#PRINT_LOG "FATAL" "Libvirt failed to start"
    #fn_writeResultFile "${RESULT_FILE}" "libvirt_start" "fail"
    #return 1
fi


#修改xml配置文件(创建一台8U16G的虚拟机)
case "${distro}" in
	centos)
	cd /var/lib/libvirt/qemu/nvram
	if [ ! -f "centos_VARS.fd" ];then	
		wget ${ci_http_addr}/test_dependents/centos_VARS.fd
	fi
	cd -
	if [ ! -f "centos.img" ];then
		wget ${ci_http_addr}/test_dependents/centos.img
	fi

	cp centos.img centos1.img 
	cp centos.img centos2.img
	cp centos.img centos3.img
	cp centos.img centos4.img
			
	cp centos_libvirt_demo4.xml kvm1.xml
	cp centos_libvirt_demo4.xml kvm2.xml
	cp centos_libvirt_demo4.xml kvm3.xml
	cp centos_libvirt_demo4.xml kvm4.xml
	
	#kvm1
	sed -i "s%<name>centos</name>%<name>kvm1</name>%g" kvm1.xml
	sed -i "s%<uuid>e06d5011-2de4-48a0-834e-72eecf7c99f0</uuid>%<uuid>${random_uuid1}</uuid>%g" kvm1.xml
	sed -i "s%<source file='/home/dingyu/centos.img'/>%<source file='${path}/centos1.img'/>%g" kvm1.xml
	sed -i "s%<mac address='52:54:00:92:4c:7e'/>%<mac address='52:54:00:92:4c:${random_mac1}'/>%g" kvm1.xml
			
	#kvm2
	sed -i "s%<name>centos</name>%<name>kvm2</name>%g" kvm2.xml
	sed -i "s%<uuid>e06d5011-2de4-48a0-834e-72eecf7c99f0</uuid>%<uuid>${random_uuid2}</uuid>%g" kvm2.xml
	sed -i "s%<source file='/home/dingyu/centos.img'/>%<source file='${path}/centos2.img'/>%g" kvm2.xml
	sed -i "s%<mac address='52:54:00:92:4c:7e'/>%<mac address='52:54:00:92:4c:${random_mac2}'/>%g" kvm2.xml
			
	#kvm3
	sed -i "s%<name>centos</name>%<name>kvm3</name>%g" kvm3.xml
	sed -i "s%<uuid>e06d5011-2de4-48a0-834e-72eecf7c99f0</uuid>%<uuid>${random_uuid3}</uuid>%g" kvm3.xml
	sed -i "s%<source file='/home/dingyu/centos.img'/>%<source file='${path}/centos3.img'/>%g" kvm3.xml
	sed -i "s%<mac address='52:54:00:92:4c:7e'/>%<mac address='52:54:00:92:4c:${random_mac3}'/>%g" kvm3.xml
			
	#kvm4
	sed -i "s%<name>centos</name>%<name>kvm4</name>%g" kvm4.xml
	sed -i "s%<uuid>e06d5011-2de4-48a0-834e-72eecf7c99f0</uuid>%<uuid>${random_uuid4}</uuid>%g" kvm4.xml
	sed -i "s%<source file='/home/dingyu/centos.img'/>%<source file='${path}/centos4.img'/>%g" kvm4.xml
	sed -i "s%<mac address='52:54:00:92:4c:7e'/>%<mac address='52:54:00:92:4c:${random_mac4}'/>%g" kvm4.xml
	;;
	esac

}

#测试执行
function test_case()
{
#****************虚拟机 1  ***********************
#创建虚拟机1
virsh define kvm1.xml
print_info $? kvm1_define
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine was created successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm1_define" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "The virtual machine creation failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm1_define" "fail"
    #return 1
#fi

#启动虚拟机1
virsh start kvm1
print_info $? kvm1_start
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine started successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm1_start" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine startup failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm1_start" "fail"
    #return 1
#fi	

#连接虚拟机1
EXPECT=$(which expect)	
$EXPECT <<EOF
set timeout 100
spawn virsh console kvm1 
expect {
" is ^]" {send "\03";exp_continue} 
"login:" {send "root\r";exp_continue}
"assword:" {send "root\r"}
}

expect "]#" 
send "ip a\r"
expect eof
EOF

print_info $? kvm1_connect
	
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine connected successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm1_connect" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine connection failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm1_connect" "fail"
    #return 1
#fi

#****************虚拟机 2  ***********************
#创建虚拟机2
virsh define kvm2.xml
print_info $? kvm2_define
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine was created successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm2_define" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "The virtual machine creation failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm2_define" "fail"
    #return 1
#fi

#启动虚拟机2
virsh start kvm12
print_info $? kvm2_start
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine started successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm2_start" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine startup failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm2_start" "fail"
    #return 1
#fi	

#连接虚拟机2
EXPECT=$(which expect)	
$EXPECT <<EOF
set timeout 100
spawn virsh console kvm2
expect {
" is ^]" {send "\03";exp_continue} 
"login:" {send "root\r";exp_continue}
"assword:" {send "root\r"}
}

expect "]#" 
send "ip a\r"
expect eof
EOF
	
print_info $? kvm2_connect
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine connected successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm2_connect" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine connection failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm2_connect" "fail"
    #return 1
#fi

#****************虚拟机 3  ***********************
#创建虚拟机3
virsh define kvm3.xml
print_info $? kvm3_define
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine was created successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm3_define" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "The virtual machine creation failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm3_define" "fail"
    #return 1
#fi

#启动虚拟机3
virsh start kvm3
print_info $? kvm3_start
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine started successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm3_start" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine startup failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm3_start" "fail"
    #return 1
#fi	

#连接虚拟机3
EXPECT=$(which expect)	
$EXPECT <<EOF
set timeout 100
spawn virsh console kvm3 
expect {
" is ^]" {send "\03";exp_continue} 
"login:" {send "root\r";exp_continue}
"assword:" {send "root\r"}
}

expect "]#" 
send "ip a\r"
expect eof
EOF

print_info $? kvm3_connect
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine connected successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm3_connect" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine connection failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm3_connect" "fail"
    #return 1
#fi

#****************虚拟机 4  ***********************
#创建虚拟机4
virsh define kvm4.xml
print_info $? kvm4_define
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine was created successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm4_define" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "The virtual machine creation failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm4_define" "fail"
    #return 1
#fi

#启动虚拟机4
virsh start kvm4
print_info $? kvm4_start
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine started successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm4_start" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine startup failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm4_start" "fail"
    #return 1
#fi	

#连接虚拟机4
EXPECT=$(which expect)	
$EXPECT <<EOF
set timeout 100
spawn virsh console kvm4
expect {
" is ^]" {send "\03";exp_continue} 
"login:" {send "root\r";exp_continue}
"assword:" {send "root\r"}
}

expect "]#" 
send "ip a\r"
expect eof
EOF

print_info $? kvm4_connect
#if [ $? -eq 0 ];then
	#PRINT_LOG "INFO" "The virtual machine connected successfully"
    #fn_writeResultFile "${RESULT_FILE}" "kvm4_connect" "pass"
    #return 0 
#else
	#PRINT_LOG "FATAL" "Virtual machine connection failed"
    #fn_writeResultFile "${RESULT_FILE}" "kvm4_connect" "fail"
    #return 1
#fi


}


#恢复环境
function clean_env()
{

#停止虚拟机
virsh destroy kvm1
virsh destroy kvm2
virsh destroy kvm3
virsh destroy kvm4

#删除虚拟机
virsh undefine --nvram kvm1
virsh undefine --nvram kvm2
virsh undefine --nvram kvm3
virsh undefine --nvram kvm4

#停止libvirt服务
systemctl stop libvirtd



}



function main()
{
    init_env 
    test_case 
    clean_env 
}

main $@
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}









