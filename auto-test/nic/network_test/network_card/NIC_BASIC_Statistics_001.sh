#!/bin/bash
#用例名称：NIC_BASIC_Statistics_001
#用例功能：GE网口标准统计数据获取功能测试
#作者：lwx652446
#完成时间：2019-1-30
#前置条件
#    1.单板启动正常
#    2.所有GE网口各模块加载正常
#测试步骤
#    1.执行ifconfig 网口名，有结果A）
#    2.执行ifconfig 网口名 ，网口名不存在，有结果B）
#测试结果
#    A）正确显示网口信息，ip、mac地址，收发包统计，重点关注dropped、overruns字段
#    B）显示设备不存在
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

#测试
function test_case()
{
        pkgs="net-tools ethtool"
        install_deps "${pkgs}"
#查找存在GE网口

	eth=`ip link | grep "state UP" | awk '{ print $2 }' | sed 's/://g'|grep -v vir`
	echo $eth
        for network_interface in  $eth
        do
             ethtool $network_interface|grep Speed|grep "1000Mb/s"
             if [ $? -eq 0 ]; then
                 echo "$network_interface" | tee -a tt.txt
             fi
         done 
         en=`cat tt.txt`
               for j in $en
                   do
                      ifconfig $j
                      ifconfig $j|grep "dropped"
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "drop"
                          fn_writeResultFile "${RESULT_FILE}" "drop is have" "pass"
                      else
                          PRINT_LOG "FATAL" "drop"
                          fn_writeResultFile "${RESULT_FILE}" "drop is not" "fail"
                       fi

                      ifconfig $j|grep "overruns"
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "overruns"
                          fn_writeResultFile "${RESULT_FILE}" "overruns is have" "pass"
                      else
                          PRINT_LOG "FATAL" "overruns"
                          fn_writeResultFile "${RESULT_FILE}" "overruns is not" "fail"
                       fi

                      ifconfig $j|grep "ether"|awk '{print $2}'
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "ether"
                          fn_writeResultFile "${RESULT_FILE}" "ether is have" "pass"
                      else
                          PRINT_LOG "FATAL" "ether"
                          fn_writeResultFile "${RESULT_FILE}" "ether is not" "fail"
                       fi

                      ifconfig $j|grep "inet"|awk '{print $2}'
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "inet"
                          fn_writeResultFile "${RESULT_FILE}" "inet is have" "pass"
                      else
                          PRINT_LOG "FATAL" "inet"
                          fn_writeResultFile "${RESULT_FILE}" "inet is not" "fail"
                      fi


	          done
# 查找不存在的网口                                 
	ifconfig xxx 2>&1 |tee -a kk.txt
	cat kk.txt |grep "Device not found"
	if [ $? ];then
           PRINT_LOG "INFO" "XX is"
           fn_writeResultFile "${RESULT_FILE}" "device is have" "pass"
	else
           PRINT_LOG "FATAL" "XX"
           fn_writeResultFile "${RESULT_FILE}" "device" "fail"

        fi
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


