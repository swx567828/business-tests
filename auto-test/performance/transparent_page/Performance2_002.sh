#!/bin/bash
set -x

#********************************************************************************
# *用例编号： Performance2_002
# *用例名称： 透明页模式设置                      
# *作者：dwx588814                            
# *完成时间：20192/20                        
# *前置条件：
#    1 D06服务器1台
# *测试步骤:
#    1 root用户登录单板
#    2 执行echo always > /sys/kernel/mm/transparent_hugepage/enabled
#    3 echo always > /sys/kernel/mm/transparent_hugepage/defrag
#    4 cat /sys/kernel/mm/transparent_hugepage/enabled
#    5 cat /sys/kernel/mm/transparent_hugepage/defrag
# *测试结果
#    1 查看到enabled文件内容为：[always] madvise never
#    2 查看到defrag文件内容为：[always] defer defer+madvise madvise never


#加载公共函数,具体看环境对应的位置修改
. ../../../utils/test_case_common.inc
. ../../../utils/error_code.inc
. ../../../utils/sys_info.sh
. ../../../utils/sh-test-lib      

#获取脚本名称作为测试用例名称
test_name=$(basename $0 | sed -e 's/\.sh//')
#创建log目录
TMPDIR=/var/logs_test/temp
mkdir -p ${TMPDIR}
#存放脚本处理中间状态/值等
TMPFILE=${TMPDIR}/${test_name}.tmp
#存放每个测试步骤的执行结果
RESULT_FILE=${TMPDIR}/${test_name}.result
test_result="pass"


#预置条件
function init_env()
{

#检查结果文件是否存在，创建结果文件
fn_checkResultFile ${RESULT_FILE}

#root用户执行
if [ `whoami` != 'root' ]
then
     echo  " You must be root user " 
     return 1
fi

}

#测试执行
function test_case()
{

#透明页模式设置
echo always > /sys/kernel/mm/transparent_hugepage/enabled

#查看是否设置成功
Enable=`cat /sys/kernel/mm/transparent_hugepage/enabled |grep "[always]"`
if [[ "$Enable" =~ "[always]" ]];then
    fn_writeResultFile "${RESULT_FILE}" "set_enable" "pass"
    PRINT_LOG "INFO" "set enable is success"
else 
    fn_writeResultFile "${RESULT_FILE}" "set_enable" "fail"
    PRINT_LOG "FATAL" "set enable is fail"
fi


echo always > /sys/kernel/mm/transparent_hugepage/defrag

Defrag=`cat /sys/kernel/mm/transparent_hugepage/defrag |grep "[always]"`
if [[ "$Defrag" =~ "[always]" ]];then
    fn_writeResultFile "${RESULT_FILE}" "set_defrag" "pass"
    PRINT_LOG "INFO" "set defrag is success"
else
    fn_writeResultFile "${RESULT_FILE}" "set_defrag" "fail"
    PRINT_LOG "FATAL" "set defrag is fail"
fi

}



function main()
{

init_env || test_result="fail"
if [ ${test_result} = "pass" ]
then
    test_case || test_result="fail"
fi
[ "${test_result}" = "pass" ] || return 1


}

main 
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
























