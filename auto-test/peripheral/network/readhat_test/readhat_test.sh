#!/bin/bash

#*****************************************************************************************
# *用例名称：Check_009
# *用例功能：板载网口个数检查
# *作者：fwx654472
# *完成时间：2019-1-21
# *前置条件：
#   1、D06服务器一台
# *测试步骤：
#   1 进入操作系统
#   2 使用ip a命令查询网口信息
# *测试结果：
#   1 可以查询到板载网口
#*****************************************************************************************


#加载公共函数,具体看环境对应的位置修改
. ../../../../utils/error_code.inc
. ../../../../utils/test_case_common.inc
. ../../../../utils/sys_info.sh
. ../../../../utils/sh-test-lib     

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


function fn_get_hns_network_card() 
{

    [ -n "$1" ] || PRINT_LOG "Usage:parameter 1 is not none .eg: fn_get_physical_network_card physical_network_interface_list"
    declare -a hns_network_card
    
    network_interface_list=`ip a | grep ^[[:digit:]] | egrep -v "lo|vi|br" | awk -F":" '{print $2}'`
    j=0
    for i in ${network_interface_list}
    do
        ethtool -i ${i} | grep "driver" | grep "hns"
        if [ $? -eq 0 ]
        then
            physical_network_card[j]=$i
            let j++
            PRINT_LOG "INFO" "hns_network_card[$j]=$i"
        else
            PRINT_LOG "WARN" "network interface :$i"
        fi    
    done
    
    eval $1='${physical_network_card[@]}'

}

function init_env()
{
    #检查结果文件是否存在，创建结果文件：
    fn_checkResultFile ${RESULT_FILE}

}

function test_case()
{
    fn_get_physical_network_card hns_network_interface_list
    PRINT_LOG "INFO" "hns_network_interface_list<${hns_network_interface_list}>"
	if [ ${#hns_network_interface_list[@]} = 0 ]
	then
		fn_writeResultFile "${RESULT_FILE}" "hns_network_interface" "fail"
	else
		fn_writeResultFile "${RESULT_FILE}" "hns_network_interface" "pass"
	fi
   
    PRINT_LOG "INFO" "NUM:${#hns_network_interface_list[@]}"
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
}

main $@
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
