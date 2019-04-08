#!/bin/bash

#用例名称：version_001               
#用例功能：检查操作系统版本 
#作者：fwx654472                            
#完成时间：2019-1-22                        
#前置条件：                                 
# 1、D06服务器1台        
#测试步骤：                                 
#1 启动单板并登录系统
#2 执行cat /etc/os-release检查操作系统版本信息
#测试结果：
#   获取操作系统类型
#######################################################################
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
#var_name1="xxxx"
#var_name2="xxxx"
test_result="pass"
    


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

#测试执行
function test_case()
{
    #测试步骤实现部分
    os_type=`cat /etc/os-release | grep -w ID | awk -F"=" '{print $2}' | tr '[:upper:]' '[:lower:]'`
    if [ $? -eq 0 ]
    then
        PRINT_LOG "INFO" "Get OS type<os_type> success"
    else
        PRINT_LOG "INFO" "Get OS type<os_type> success"
    fi
    
    if [ ${os_type} = \"suse\" ] || [ ${os_type} = "suse" ] || [ ${os_type} = \"sles\" ] || [ ${os_type} = "sles" ]
    then
        os_type=suse
    elif [ ${os_type} = \"ubuntu\" ] || [ ${os_type} = "ubuntu" ]
    then
        os_type=ubuntu
    elif [ ${os_type} = \"redhat\" ] || [ ${os_type} = "redhat" ] || [ ${os_type} = \"rhel\" ] || [ ${os_type} = "rhel" ]
    then
        os_type=redhat
    elif [ ${os_type} = \"centos\" ] || [ ${os_type} = "centos" ] 
    then
        os_type=centos
    elif [ ${os_type} = \"debian\" ] || [ ${os_type} = "debian" ]
    then
        os_type=debian
    fi
    
    echo "${os_type}" | egrep  -i "suse|ubuntu|centos|redhat|debian" 
    if [ $? -eq 0 ]
    then
        PRINT_LOG "INFO" "this system is ${os_type},test is success" 
        fn_writeResultFile "${RESULT_FILE}" "${os_type}" "pass"
    else
        PRINT_LOG "WARN" "this system is ${os_type},test is fail ,please check it " 
        fn_writeResultFile "${RESULT_FILE}" "${os_type}" "fail"
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
}

main $@
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
