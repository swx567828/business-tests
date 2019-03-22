#!/bin/bash

#*****************************************************************************************
# *用例名称：Suse_Relevant_005
# *用例功能: 查看suse系统是否支持qperf
# *作者：mwx547872
# *完成时间：2019-2-21
# *前置条件：
#   1、预装suse操作系统
# *测试步骤：
#   1、 进入suse操作系统。
#   2.  使用zypper info 命令检查是否有qperf安装包
# *测试结果：
#  可以检查到qperf安装包
#*****************************************************************************************

#加载公共函数
. ../../../utils/test_case_common.inc
. ../../../utils/error_code.inc
. ../../../utils/sys_info.sh
. ../../../utils/sh-test-lib

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
        if [ `whoami` != 'root' ]; then
            echo "You must be the superuser to run this script" > $2
            exit 1
        fi

          sys_info=$(cat /etc/os-release |grep PRETTY_NAME)
         # if [ "$(echo $sys_info |grep "SUSE")" != ""x ];then
          #     PRINT_LOG "INFO" "system is suse"
          #else
           #    PRINT_LOG "FAIAL" "systemm is not suse"
            #   exit 1
          #fi
}

#测试执行
function test_case()
{
        check_result ${RESULT_FILE}
        package=`yum info coreutils|grep "Name"|awk -F ':' '{print $2}'|sed 's/ //g'|head -1`
        if [ "$package" = "cp" ];then
        #     PRINT_LOG "INFO" "suse have cp package"
             print_info 0 cp-package
        else
         #    PRINT_LOG "FAIAL" "suse no have cp package"
             print_info 1 cp-package
        fi


}

function main()
{
        init_env
        test_case

}

main
#ret=$?
#LAVA平台上报结果接口，勿修改
#lava-test-case "$test_name" --result ${test_result}
#exit ${ret}
