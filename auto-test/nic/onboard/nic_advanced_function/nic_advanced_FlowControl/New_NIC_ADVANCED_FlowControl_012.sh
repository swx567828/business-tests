#!/bin/bash

#*****************************************************************************************
# *用例名称：New_NIC_ADVANCED_FlowControl_012                                                       
# *用例功能：网卡PAUSE能力检查                                              
# *作者：lwx588815                                                          
# *完成时间：2019-4-10                                                               
# *前置条件：                                                                            
#      1.网卡未设置过参数
#      2.所有网口已连接                                                                  
# *测试步骤：                                                                               
#      1、执行命令ethtool ethx查看被测网卡的支持的PAUSE能力
#      2、遍历网口  
# *测试结果：                                                                            
#      1.Supported pause frame use: Symmetric                                                       
#*****************************************************************************************

#加载公共函数
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
        #install
        fn_install_pkg "ethtool" 2

}       


#测试执行
function test_case()
{
    network=`ip link | grep "state UP" | awk '{ print $2 }' | sed 's/://g'|egrep -v "vir|br|docker|vnet"`
    for i in $network
    do
      ethtool -A $i rx on tx on
      sleep 5
      PaUSE=`ethtool $i|grep "Supported pause frame use:"|awk '{print $5}'`
      if [ "$PaUSE"x = "Symmetric"x ];then
          PRINT_LOG "INFO" "$i have Symmetric"
          fn_writeResultFile "${RESULT_FILE}" "$i have Symmetric" "pass"
      else
          PRINT_LOG "FATAL" "$i not have Symmetric"
          fn_writeResultFile "${RESULT_FILE}" "$i not have Symmetric" "fail"
      fi
    done 
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
