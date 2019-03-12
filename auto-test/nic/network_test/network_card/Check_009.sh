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
#   1 可以查询到板载网口4个（enp125s0f0、enp125s0f1、enp125s0f2、enp125s0f3）                                                         
#*****************************************************************************************

#加载公共函数
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
TMPCFG=${TMPDIR}/${test_name}.tmp_cfg
test_result="pass"



#预置条件
function init_env()
{
  #检查结果文件是否存在，创建结果文件：
    fn_checkResultFile ${RESULT_FILE}

}


#测试执行
function test_case()
{
    #测试步骤实现部分
    ip link > ${TMPFILE} 2>&1 
    if [ $? -eq 0 ]
    then
        PRINT_LOG "INFO" "Exec <ip a> cmd is ok"
        fn_writeResultFile "${RESULT_FILE}" "cmd_ip_a" "pass"
        cat ${TMPFILE} | grep "enp125s0f0" || fn_writeResultFile "${RESULT_FILE}" "enp125s0f0" "fail"
        cat ${TMPFILE} | grep "enp125s0f1" || fn_writeResultFile "${RESULT_FILE}" "enp125s0f1" "fail"
        cat ${TMPFILE} | grep "enp125s0f2" || fn_writeResultFile "${RESULT_FILE}" "enp125s0f2" "fail"
        cat ${TMPFILE} | grep "enp125s0f3" || fn_writeResultFile "${RESULT_FILE}" "enp125s0f3" "fail"
    else
        PRINT_LOG "WARN" "Exec <ip a> cmd is fail " 
        fn_writeResultFile "${RESULT_FILE}" "cmd_ip_a" "fail"
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
    PRINT_LOG "INFO" "end of running test case<${test_name}>"
}


function main()
{
    init_env || test_result="fail"
    if [ ${test_result} = "pass" ]
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
