#!/bin/bash

#*****************************************************************************************
#用例名称：NIC_BASIC_Negotiation_001
#用例功能：网卡PCIE自协商测试
#作者：hwx653129
#完成时间：2019-1-28

#前置条件：
# 	无

#测试步骤：
# 	1. 将网卡插到PCIE槽上，单板上电，进入系统后，通过lspic |grep -I eth查看到是否能找到网卡，lspci -vvv 查询网卡协商是否正常，有结果A)
# 	2. 配置IP检查网卡是否能正常通信，有结果B)
# 	3. 支持的网卡需要遍历支持的PCIE槽位，重复步骤1-2

#测试结果:
# 	A) OS下能找到网卡，网卡PCIe 协商速率带宽LnkSta字段显示的值正常
# 	B) 网卡能正常通信。                                               
#*****************************************************************************************

#加载公共函数,具体看环境对应的位置修改
. ../../../../utils/error_code.inc
. ../../../../utils/test_case_common.inc
. ../../../../utils/sys_info.sh
. ../../../../utils/sh-test-lib
#. ./utils/error_code.inc
#. ./utils/test_case_common.inc 
 
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

	#去除非目录文件
	for ((i=0;i<${len_virtual};i++))
	do
		if [ ! -d "/sys/devices/virtual/net/${virtual_network_cards[i]}" ]; then
			unset virtual_network_cards[i]
		fi	
	done

	#去除虚拟网卡
	for ((i=0;i<${len_total};i++))
	do
		for ((j=0;j<${len_virtual};j++))
		do
			if [ "${total_network_cards[i]}" == "${virtual_network_cards[j]}" ]; then
				unset total_network_cards[i]
			fi
		done	
	done

	for net in ${virtual_network_cards[@]}
	do
		PRINT_LOG "INFO" "please check this $net port"
	done
	
}
#************************************************************#
# Name        : verify_negotiate                               #
# Description : 确认网卡协商速率                               #
# Parameters  : 无                                           #
#************************************************************#
function verify_negotiate(){
	for net in ${total_network_cards[@]}
	do
		bus_num=`ethtool -i $net | grep bus | awk '{print $2}'`
		LnkSta=`lspci -s $bus_num -vvv | grep LnkSta: | cut -d " " -f 2`
		LnkCap=`lspci -s $bus_num -vvv | grep LnkCap: | cut -d " " -f 4`	
		if [ "$LnkSta" == "$LnkCap" ]
		#网卡协商正常
		then 
			PRINT_LOG "INFO" "$net standard speed is equal to capacity speed."
			fn_writeResultFile "${RESULT_FILE}" "$net speed negotiate" "pass"
		else
			PRINT_LOG "FATAL" "$net standard speed is not equal to capacity speed, please check it."
			fn_writeResultFile "${RESULT_FILE}" "$net speed negotiate" "fail"
			return 1
		fi	
	done
}
#************************************************************#
# Name        : verify_connect                               #
# Description : 确认网卡连通性                               #
# Parameters  : 无                                           #
#************************************************************#
function verify_connect(){
	#打开所有网口
	for net in ${total_network_cards[@]}
	do
		ip link set dev $net up
		sleep 2
	done
	#查找链路正常的网口		
	for net in ${total_network_cards[@]}
	do
		ip a add 10.28.26.18/24 dev $net
		echo "$net ping test ...."
		ping 10.28.26.18 -c 5
		if [ $? -eq 0 ]
		#网卡连通正常
		then 
			PRINT_LOG "INFO" "$net connectivity normal."
			fn_writeResultFile "${RESULT_FILE}" "$net connectivity" "pass"
		else
			PRINT_LOG "FATAL" "$net connectivity isn't normal, please check it."
			fn_writeResultFile "${RESULT_FILE}" "$net connectivity" "fail"
			return 1
		fi
		ip a del 10.28.26.18/24 dev $net
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
	find_physical_card
    #自定义测试预置条件检查实现部分：比如工具安装，检查多机互联情况，执行用户身份 
      #需要安装工具，使用公共函数install_deps，用法：install_deps "${pkgs}"
      #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
}

#测试执行
function test_case()
{
	for ((i=1;i<=2;i++))
	do
		verify_negotiate
		verify_connect
	done
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