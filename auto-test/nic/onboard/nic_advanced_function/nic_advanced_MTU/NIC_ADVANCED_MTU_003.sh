#!/bin/bash

#*****************************************************************************************
#用例名称：NIC_ADVANCED_MTU_003
#用例功能：网口MTU查询
#作者：cwx615603
#完成时间：2019-1-25

#前置条件：
#    1.单板启动正常
#    2.所有网口各模块加载正常

#测试步骤：
#    1.修改68~9702之外的mtu值：ip link set dev eth2 mtu 67
#                              ip link set dev eth2 mtu 9708，结果1）
#    2.修改无效的mtu值：ip link set dev eth2 mtu xxx，结果1）
#    3.修改不存在的设备，ip link set dev xxx mtu 1800，结果2）

#测试结果:
# 	 1.修改失败，无效的mtu值
#    2.xxx设备不存在                                      
#*****************************************************************************************

#加载公共函数,具体看环境对应的位置修改
. ../../../../../utils/error_code.inc
. ../../../../../utils/test_case_common.inc
. ../../../../../utils/sys_info.sh
. ../../../../../utils/sh-test-lib

#. ../../utils/error_code.inc
#. ../../utils/test_case_common.inc
#. ./error_code.inc
#. ./test_case_common.inc
 
#获取脚本名称作为测试用例名称
test_name=$(basename $0 | sed -e 's/\.sh//')
#创建log目录
TMPDIR=./logs/temp
mkdir -p ${TMPDIR}
#存放脚本处理中间状态/值等
TMPFILE=${TMPDIR}/${test_name}.tmp
#存放每个测试步骤的执行结果
RESULT_FILE=${TMPDIR}/${test_name}.result

#自定义变量区域（可选）
#var_name1="xxxx"
#var_name2="xxxx"
test_result="pass"

#************************************************************#
# Name        : find_physical_card                                        #
# Description : 查询物理网卡                                 #
# Parameters  : 无           #
# return value：total_network_cards[]
#************************************************************#
function find_physical_card(){
	total_network_cards=(`ls /sys/class/net/`)
	virtual_network_cards=(`ls /sys/devices/virtual/net/`)
	len_total=${#total_network_cards[@]}
	len_virtual=${#virtual_network_cards[@]}
	
	#去除非目录文件
	for ((i=0;i<${len_total};i++))
	do
		if [ ! -d "/sys/class/net/${total_network_cards[i]}" ]; then
			unset total_network_cards[i]
		fi	
	done
	total_network_cards=(`echo ${total_network_cards[@]}`)

	#去除非目录文件
	for ((i=0;i<${len_virtual};i++))
	do
		if [ ! -d "/sys/devices/virtual/net/${virtual_network_cards[i]}" ]; then
			unset virtual_network_cards[i]
		fi	
	done
	virtual_network_cards=(`echo ${virtual_network_cards[@]}`)

	#去除虚拟网卡
	for ((i=0;i<${len_total};i++))
	do
		for ((j=0;j<${len_virtual};j++))
		do
			if [ "${total_network_cards[i]}" == "${virtual_network_cards[j]}" ]; then
				unset total_network_cards[i]				
				break
			fi
		done	
	done
	total_network_cards=(`echo ${total_network_cards[@]}`)
	
	for net in ${virtual_network_cards[@]}
	do
		PRINT_LOG "INFO" "please check this $net port"
	done	
}
#************************************************************#
# Name        : verify_network_module                        #
# Description : 确认网络模块                                 #
# Parameters  : 无
# return      : 无                                      #
#************************************************************#
function verify_network_module(){
	#查找所有物理网卡
	#find_physical_card
	
	#保存所有网卡驱动	
	for ((i=0;i<${#total_network_cards[@]};i++))
	do
		driver[i]=`ethtool -i ${total_network_cards[i]} | grep driver | awk '{print $2}'`
	done
	
	#删除重复驱动
	len=${#driver[@]}
	#控制循环次数
	for ((i=0;i<${len}-1;i++))
	do
		#与下一个元素比较，直到最后一个相同则删除
		for ((j=i+1;j<${len};j++))
		do
			if [ "${driver[i]}" == "${driver[j]}" ]; then
				unset driver[i]
				break
			fi
		done
	done
	driver=(`echo ${driver[@]}`)
	
	for d in ${driver[@]}
	do
		if [ ! $d ];then
			PRINT_LOG "FATAL" "some error or fail with this $d module"
			fn_writeResultFile "${RESULT_FILE}" "$d module error or fail" "fail"
			return 1
		else
			PRINT_LOG "INFO" "This $d module is normal"
			fn_writeResultFile "${RESULT_FILE}" "$d module normal" "pass"
		fi
	done
}

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
	ethtool -h || fn_install_pkg "ethtool" 10
	find_physical_card
	verify_network_module
    #自定义测试预置条件检查实现部分：比如工具安装，检查多机互联情况，执行用户身份 
      #需要安装工具，使用公共函数install_deps，用法：install_deps "${pkgs}"
      #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
}

#测试执行
function test_case()
{
	#给网口配置MAC地址

	for net in ${total_network_cards[@]}
	do	
		ip link set dev $net mtu 65
		if [ $? -eq 0 ];then
			PRINT_LOG "FATAL" "This $net port mtu modified success, please check."
			PRINT_LOG "FATAL" "exec<ip link set dev $net mtu 65>"
			fn_writeResultFile "${RESULT_FILE}" "$net mtu 65" "fail"
		else
			PRINT_LOG "INFO" "This $net port mtu value 65 is Invalid."
			fn_writeResultFile "${RESULT_FILE}" "$net mtu 65" "pass"
		fi
			
		ip link set dev $net mtu 9800
		if [ $? -eq 0 ];then
			PRINT_LOG "FATAL" "This $net port mtu modified success, please check."
			PRINT_LOG "FATAL" "exec<ip link set dev $net mtu 9800>"
			fn_writeResultFile "${RESULT_FILE}" "$net mtu 9800" "fail"
		else
			PRINT_LOG "INFO" "This $net port mtu value 9800 is Invalid."
			fn_writeResultFile "${RESULT_FILE}" "$net mtu 9800" "pass"
		fi
		
		ip link set dev $net mtu xxx
		if [ $? -eq 0 ];then
			PRINT_LOG "FATAL" "This $net port mtu modified success, please check."
			PRINT_LOG "FATAL" "exec<ip link set dev $net mtu xxx>"
			fn_writeResultFile "${RESULT_FILE}" "$net mtu xxx" "fail"
		else
			PRINT_LOG "INFO" "This $net port mtu value xxx is wrong."
			fn_writeResultFile "${RESULT_FILE}" "$net mtu xxx" "pass"
		fi
	done
	
	ip link set dev xxx mtu 1800
	if [ $? -eq 0 ];then
		PRINT_LOG "FATAL" "This xxx port mtu modified success, please check."
		PRINT_LOG "FATAL" "exec<ip link set dev xxx mtu 1800>"
		fn_writeResultFile "${RESULT_FILE}" "xxx mtu 1800" "fail"
	else
		PRINT_LOG "INFO" "cannot find device xxx."
		fn_writeResultFile "${RESULT_FILE}" "xxx mtu 1800" "pass"
	fi
    #检查结果文件，根据测试选项结果，有一项为fail则修改test_result值为fail，
    check_result ${RESULT_FILE}
}


#恢复环境
function clean_env()
{
    #清除临时文件
    FUNC_CLEAN_TMP_FILE
    #自定义环境恢复实现部分,工具安装不建议恢复
      #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
}


function main()
{
    init_env || test_result="fail"
    if [ ${test_result} = 'pass' ]
    then
        test_case || test_result="fail"
    fi
    clean_env || test_result="fail"
	[ "${test_result}" = "pass" ] || return 1
}

main $@
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
