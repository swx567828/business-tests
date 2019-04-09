#!/bin/bash

#用例名称：NIC_ADVANCED_GSO_002              
#用例功能：业务网口GSO设置查询测试
#作者：cwx615603                   
#完成时间：2019-2-12                        
#前置条件：                                 
#1.单板启动正常
#2.所有网口各模块加载正常           
#测试步骤：                                 
#1. 调用命令“ethtool -k ethx”查询当前的GSO设置，有结果A）
#2. 调用命令“ethtool -K ethx gso off”修改GSO设置，并查询，有结果B）
#3. 调用命令“ethtool -K ethx gso on”修改GSO设置，并查询，有结果A）
#4. 遍历所有网口
#测试结果：
#A）generic-segmentation-offload: on
#B）generic-segmentation-offload: off

#加载公共函数
. ../../../../utils/error_code.inc
. ../../../../utils/test_case_common.inc
. ../../../../utils/sys_info.sh
. ../../../../utils/sh-test-lib 		
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
##************************************************************#
# Name        : gso_check                                     #
# Description : 测试网口gso功能                               #
# Parameters  : $1 net_port                                   #
#*************************************************************#
function gso_check(){
	#查看默认状态
	gso_status=`ethtool -k $1 |grep generic-segmentation-offload|awk -F " " '{print $2}'`
	if [ "$gso_status" != "on" ]
	then
		PRINT_LOG "FATAL" "The $1 gso initial state is off, please check it"
		fn_writeResultFile "${RESULT_FILE}" "$1 gso initial state is off" "fail"
	else
		PRINT_LOG "INFO" "The $1 gso initial state is on"
		fn_writeResultFile "${RESULT_FILE}" "$1 gso initial state is on" "pass"
	fi
	
	#关闭gso
	ethtool -K $1 gso off ;sleep 3
	gso_status=`ethtool -k $1 |grep generic-segmentation-offload|awk -F " " '{print $2}'`
	if [ "$gso_status" != "off" ]
	then
		PRINT_LOG "FATAL" "$1 gso set to off fail"
		fn_writeResultFile "${RESULT_FILE}" "$1 gso set to off" "fail"
	else
		PRINT_LOG "INFO" "$1 gso set to off pass"
		fn_writeResultFile "${RESULT_FILE}" "$1 gso set to off" "pass"
	fi
	
	#开启gso
	ethtool -K $1 gso on ;sleep 3
	gso_status=`ethtool -k $1 |grep generic-segmentation-offload|awk -F " " '{print $2}'`
	if [ "$gso_status" != "on" ]
	then
		PRINT_LOG "FATAL" "$1 gso set to on fail"
		fn_writeResultFile "${RESULT_FILE}" "$1 gso set to on" "fail"
	else
		PRINT_LOG "INFO" "$1 gso set to on pass"
		fn_writeResultFile "${RESULT_FILE}" "$1 gso set to on" "pass"
	fi
}

#预置条件
function init_env()
{
  #检查结果文件是否存在，创建结果文件：
	fn_checkResultFile ${RESULT_FILE}
	
	#root用户执行
	if [ `whoami` != 'root' ]
	then
		PRINT_LOG "INFO" "You must be root user " 
		fn_writeResultFile "${RESULT_FILE}" "Run as root" "fail"
	fi
	ethtool -h || fn_install_pkg "ethtool" 10
	find_physical_card
	verify_network_module
}

function test_case(){
	#查询所有网口
	for net in ${total_network_cards[@]}
	do
		gso_check $net
	done
	check_result ${RESULT_FILE}
}

#恢复环境
function clean_env()
{
	FUNC_CLEAN_TMP_FILE
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

