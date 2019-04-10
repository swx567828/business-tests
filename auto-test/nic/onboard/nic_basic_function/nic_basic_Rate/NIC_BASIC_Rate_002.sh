#!/bin/bash

#用例名称：NIC_BASIC_Rate_002                 
#用例功能：网口模式查询容错测试  
#作者：fwx654472   
#完成时间：2019-1-22                        
#前置条件：                                 
#   1.单板启动正常
#   2.所有网口各模块加载正常              
#测试步骤：                                 
#1.调用命令“ethtool 网口名”，输入错误的网口名（如eth10），或者空，观察返回情况
##测试结果：
#不存在的网口提示不存在或者返回错误

#加载公共函数,具体看环境对应的位置修改
. ../../../../../utils/error_code.inc
. ../../../../../utils/test_case_common.inc
. ../../../../../utils/sys_info.sh
. ../../../../../utils/sh-test-lib     

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
tmp_network_card="ethxxxxxx"


function check_null_ethx()
{
    ethx=$1
    show_result=`ethtool ${ethx} 2>&1`
    if [ -n "${ethx}"  ]
    then
        echo "${show_result}" | grep "No data available"
        if [ $? -eq 0 ]
        then 
            PRINT_LOG "INFO" " No data available,${ethx}"
            fn_writeResultFile "${RESULT_FILE}" "test_bug_network_card" "pass"
            return 0
        else 
            PRINT_LOG "WARN" "take a mistake,${ethx}"
            fn_writeResultFile "${RESULT_FILE}" "test_bug__network_card" "fail"
            return 1
        fi
    else
        echo "${show_result}" | grep "information run ethtool -h"
        if [ $? -eq 0 ]
        then 
            PRINT_LOG "INFO" " ethtool: bad command line argument(s),${ethx}"
            fn_writeResultFile "${RESULT_FILE}" "test_none_network_card" "pass"
            return 0
        else 
            PRINT_LOG "WARN" "take a mistake,${ethx}"
            fn_writeResultFile "${RESULT_FILE}" "test_none_network_card" "fail"
            return 1
        fi      
    fi

}

function init_env()
{
    #检查结果文件是否存在，创建结果文件：
    fn_checkResultFile ${RESULT_FILE}

}

function test_case()
{
    check_null_ethx ${tmp_network_card}
    check_null_ethx 
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

