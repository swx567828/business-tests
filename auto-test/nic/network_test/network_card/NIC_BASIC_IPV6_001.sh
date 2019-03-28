#!/bin/bash

#*****************************************************************************************
#用例名称：NIC_BASIC_IPV6_001
#用例功能：ipv6支持测试
#作者：lwx652446
#完成时间：2019-2-12
#前置条件
#
#测试步骤
#   1、 单板上电启动，进入OS
#   2、 配置网卡IPV6,如ifconfig eth0 inet6 add 2001:da8:2004:1000:202:116:160:41/64 up
#	3、 测试IPV6是否能正常通信，如：ping6 2001:da8:2004:1000:202:116:160:41
#	4、 遍历所有网口
#测试结果
#   A) 能正常配置IPV6
#	B) 能正常通信
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




#测试执行
function test_case()
{
    pkgs="net-tools"
    install_deps "${pkgs}" 
#遍历所有网口，配置ipv6，通信正常
    net=`ifconfig|grep 'BROADCAST,RUNNING,MULTICAST'|egrep -v "vir|br"|awk -F: '{print $1}'`
    echo "$net"
    for i in $net
    do	
	
	ifconfig $i inet6 del 2001:da8:2004:1000:202:116:160:41 up
	ifconfig $i inet6 add 2001:da8:2004:1000:202:116:160:41 up
        sleep 5
	if [ $? -ne 0 ]
	then
		echo "set ipv6 error"
		PRINT_LOG "FATAL" "set ipv6 fail"
                fn_writeResultFile "${RESULT_FILE}" "NIC_BASIC_IPV6_001" "fail"
	else
		echo "set ipv6 ok"
		PRINT_LOG "INFO" "set ipv6 success."
                fn_writeResultFile "${RESULT_FILE}" "NIC_BASIC_IPV6_001" "pass"
	fi
	ping6 2001:da8:2004:1000:202:116:160:41 -c 3

	if [ $? -ne 0 ]
	then
		PRINT_LOG "FATAL" "ping ipv6 fail"
                fn_writeResultFile "${RESULT_FILE}" "NIC_BASIC_IPV6_001" "fail"
	else
		PRINT_LOG "INFO" "ping ipv6 success."
                fn_writeResultFile "${RESULT_FILE}" "NIC_BASIC_IPV6_001" "pass"
	fi
        ifconfig $i inet6 del 2001:da8:2004:1000:202:116:160:41 up
	
   done
#检查结果文件，根据测试选项结果，有一项为fail则修改test_result值为fail，
	check_result ${RESULT_FILE}
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
    #自定义测试预置条件检查实现部分：比如工具安装，检查多机互联情况，执行用户身份 
      #需要安装工具，使用公共函数install_deps，用法：install_deps "${pkgs}"
      #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
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


