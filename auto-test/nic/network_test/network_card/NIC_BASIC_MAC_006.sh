#!/bin/bash

#*****************************************************************************************
#用例名称：NIC_BASIC_MAC_006
#用例功能：随机MAC地址不能变
#作者：hwx653129
#完成时间：2019-1-25

#前置条件：
# 	1. 网口随机生成MAC地址

#测试步骤：
# 	1.执行网口up/down操作后，检查mac地址

#测试结果:
# 	1. 地址随机生成，网口up/down后mac地址保持不变                                                        
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
			total_network_cards=(`echo ${total_network_cards[@]}`)
		fi	
	done

	#去除非目录文件
	for ((i=0;i<${len_virtual};i++))
	do
		if [ ! -d "/sys/devices/virtual/net/${virtual_network_cards[i]}" ]; then
			unset virtual_network_cards[i]
			virtual_network_cards=(`echo ${virtual_network_cards[@]}`)
		fi	
	done

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
# Name        : check_mac                                        #
# Description : 检查mac地址前后是否一致                                 #
# Parameters  : 无           #
# return value：无
#************************************************************#
function check_mac(){
	ethx=$1
	#ifconfig $ethx down
	ip link set dev $ethx down
	pre_mac=$(ethtool -P $ethx | awk '{print $3}');
	#ifconfig $ethx up
	ip link set dev $ethx up
	sleep 2	
	aft_mac=$(ethtool -P $ethx | awk '{print $3}');
	if [ "${pre_mac}" == "${aft_mac}" ]
	then
		PRINT_LOG "INFO" "MAC address matching is consistent."
		fn_writeResultFile "${RESULT_FILE}" "$ethx MAC address is consistent" "pass"		
	else
		PRINT_LOG "FATAL" "MAC address is not the same, please check it."
		fn_writeResultFile "${RESULT_FILE}" "$ethx MAC address is inconsistent" "fail"
		return 1
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
	for net in ${total_network_cards[@]}
	do
		check_mac $net
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
	 # systemctl restart NetworkManager
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