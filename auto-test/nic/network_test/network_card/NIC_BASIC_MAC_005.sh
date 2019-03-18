#!/bin/bash
set -x
#*****************************************************************************************
#用例名称：NIC_BASIC_MAC_005
#用例功能：ethtool查询网口MAC地址
#作者：hwx653129
#完成时间：2019-1-25

#前置条件：
# 	1.单板启动正常
# 	2.所有网口各模块加载正常

#测试步骤：
# 	1.执行ethtool -P ethx查询网口MAC地址

#测试结果:
# 	1.显示网口的MAC地址                                                         
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
# Name        : find_physical_card                           #
# Description : 检查物理网卡                                 #
# Parameters  : 无 
# return	  : total_network_cards[]                        #
#************************************************************#
function find_physical_card(){
	total_network_cards=(`ls /sys/class/net/`)
	virtual_network_cards=(`ls /sys/devices/virtual/net/`)
	len_total=${#total_network_cards[@]}
	len_virtual=${#virtual_network_cards[@]}
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
# Name        : verify_network_module                        #
# Description : 确认网络模块                                 #
# Parameters  : 无     
# return	  : 无                                      #
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
			fi
		done	
	done
	
	for d in ${driver[@]}
	do
		lsmod | grep $d 

		if [ $? -eq 0 ];then

			PRINT_LOG "INFO" "This $d module load normal"
			fn_writeResultFile "${RESULT_FILE}" "$d module loaded" "pass"			
		else
			PRINT_LOG "FATAL" "This $d module load false"
			fn_writeResultFile "${RESULT_FILE}" "$d module no exist" "fail"
			lsmod
return 1
		fi
	done	
}
#************************************************************#
# Name        : verify_dmesg                              #
# Description : 检查dmesg                               #
# Parameters  : 无                                           #
#************************************************************#
function verify_dmesg(){
	dmesg|egrep -i "error|fail|warn"
	if [ $? -eq 0 ]
    then
        PRINT_LOG "FATAL" "query for exception information, please check it."
		fn_writeResultFile "${RESULT_FILE}" "query exception" "fail"
		return 1
	else
		PRINT_LOG "INFO" "no exception information."
		fn_writeResultFile "${RESULT_FILE}" "query exception" "pass"
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
	verify_network_module
	dmesg -c
    #自定义测试预置条件检查实现部分：比如工具安装，检查多机互联情况，执行用户身份 
      #需要安装工具，使用公共函数install_deps，用法：install_deps "${pkgs}"
      #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
}



#测试执行
function test_case()
{
    #ethtool查询网口MAC地址
    #ls=("enp125s0f0" "enp125s0f1" "enp125s0f2" "enp125s0f3" "enp189s0f0" "enp189s0f1")
    for net in ${total_network_cards[@]}
    do 
		ethtool -P $net
		if [ $? -eq 0 ]
		then
			PRINT_LOG "INFO" "$net has MAC address."
			fn_writeResultFile "${RESULT_FILE}" "$net normal" "pass"	
		else
			PRINT_LOG "FATAL" "$net it can not find MAC address,please check it."
			fn_writeResultFile "${RESULT_FILE}" "$net no MAC address" "fail"		
		fi
	done	
	
	ethtool -P xxx
	if [ $? -eq 0 ]
	then
		PRINT_LOG "FATAL" "query successful, please check it."
		fn_writeResultFile "${RESULT_FILE}" "no device" "fail"		
	else
		PRINT_LOG "INFO" "no such device xxx."
		fn_writeResultFile "${RESULT_FILE}" "no device" "pass"
	fi
	verify_dmesg
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
