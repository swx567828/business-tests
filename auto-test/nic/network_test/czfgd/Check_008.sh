#!/bin/bash

#*****************************************************************************************
# *用例名称：Check_008                                                         
# *用例功能：cpu核数检查                                                 
# *作者：lwx652446                                                                      
# *完成时间：2019-2-20                                                               
# *前置条件：                                                                            
#   1、D06服务器1台
#	2、系统启动正常                                                                  
# *测试步骤：                                                                               
#   '1 进入操作系统，
#	2 执行：cat /proc/cpuinfo |grep "processor"|sort -u|wc -l
#	3 观察操作情况    
# *测试结果：                                                                            
#   检查到cpu核数是96个                                                         
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



function test_cpunum()
{
	#进入系统查询cpu核数是否是96
	cpu_number=`cat /proc/cpuinfo |grep processor |sort -u|wc -l`
	echo "cpu的核数是:"$cpu_number
	if [ $cpu_number -eq 96 ]
	then
		echo "Cpu core Number is  96"
		PRINT_LOG "FATAL" "Cpu core Number is  96"
        fn_writeResultFile "${RESULT_FILE}" "Check_008" "pass"
	else		
		echo "Cpu core Number is not 96"	
        PRINT_LOG "INFO" "Cpu core Number is not 96"
        fn_writeResultFile "${RESULT_FILE}" "Check_008" "fail"		
    fi	
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





#测试执行
function test_case()
{
	test_cpunum
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