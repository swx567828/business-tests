#!/bin/bash

#*****************************************************************************************
# *用例名称：内存数量检查                                                         
# *用例功能：内存数量检查                                                 
# *作者：lwx652446                                                                      
# *完成时间：2019-2-20                                                               
# *前置条件：                                                                            
#   1、D06服务器1台
#	2、系统启动正常                                                                  
# *测试步骤：                                                                               
#   1 进入系统
#	2 执行：dmidecode -t memory |grep -i "Configured Clock Speed: 2666 MT/s"|wc -l    
# *测试结果：                                                                            
#   查询到16根内存条                                                        
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
	#查询内存条数量是否16
        mem_num=`dmidecode -t memory | grep -E "Size.*GB|Size.*MB" | awk '{print  $2 $3}'|wc -l`
  #   mem_num=`dmidecode|grep -A16 "Memory Device$"|grep Size|grep 32 |wc -l`
        echo "$mem_num"
	if [ $mem_num -eq 16 ]
	then
	    PRINT_LOG "INFO" " mem_num"
            fn_writeResultFile "${RESULT_FILE}" "mem_num" "pass"
	else 
            PRINT_LOG "FATAL" " mem_num"
            fn_writeResultFile "${RESULT_FILE}" "mem_num" "fail"
	fi
	
	#检查结果文件，根据测试选项结果，有一项为fail则修改test_result值为fail，
	check_result ${RESULT_FILE}

}

#恢复环境
function clean_env()
{
	#清除临时文件
	FUNC_CLEAN_TMP_FILE
}


function main()
{
	init_env || test_result = "fail"
	if [ ${test_result} = "pass" ]
	then
		test_case || test_result="fail"
	fi
	clean_env || test_result="fail"
	[ "${test_result}" = "fail" ] && return 1
}

main $@
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
