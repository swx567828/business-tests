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
    
    #install
    fn_install_pkg "net-tools ethtool" 2
    #自定义测试预置条件检查实现部分：比如工具安装，检查多机互联情况，执行用户身份
      #需要安装工具，使用公共函数install_deps，用法：install_deps "${pkgs}"
      #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
}

#测试
function test_case()
{

#查找存在GE网口
	network=`ip link | grep "state UP" | awk '{ print $2 }' | sed 's/://g'|egrep -v "vir|br"`
	echo $network
        for network_interface in  $network
        do
             ethtool $network_interface|grep "Supported ports:"|grep "TP"
             if [ $? -eq 0 ]; then
                 echo "$network_interface" | tee -a network.txt
             fi
        done     
                 for i in `cat network.txt`
                 do
                      ifconfig $i 2>&1 |tee iflog.txt
                      cat iflog.txt|grep "dropped"
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "$i drop is have"
                          fn_writeResultFile "${RESULT_FILE}" "$i drop is have" "pass"
                      else
                          PRINT_LOG "FATAL" "$i drop is not have"
                          fn_writeResultFile "${RESULT_FILE}" "$i drop is not have" "fail"
                       fi

                      cat iflog.txt|grep "overruns"
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "$i overruns is have"
                          fn_writeResultFile "${RESULT_FILE}" "$i overruns is have" "pass"
                      else
                          PRINT_LOG "FATAL" "$i overruns is not have"
                          fn_writeResultFile "${RESULT_FILE}" "$i overruns is not" "fail"
                       fi

                      cat iflog.txt|grep "ether"|awk '{print $2}'
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "$i ether is have"
                          fn_writeResultFile "${RESULT_FILE}" "$i ether is have" "pass"
                      else
                          PRINT_LOG "FATAL" "$i ether is not have"
                          fn_writeResultFile "${RESULT_FILE}" "$i ether is not have" "fail"
                       fi

                      cat iflog.txt|grep "inet"|awk '{print $2}'
                      if [ $? ]
                      then
                          PRINT_LOG "INFO" "$i inet is have"
                          fn_writeResultFile "${RESULT_FILE}" "$i inet is have" "pass"
                      else
                          PRINT_LOG "FATAL" "$i inet is not have"
                          fn_writeResultFile "${RESULT_FILE}" "$i inet is not have" "fail"
                      fi
	          done

# 查找不存在的网口                                 
	ifconfig xxx 2>&1 |tee kk.txt
	cat kk.txt |grep "Device not found"
	if [ $? ];then
           PRINT_LOG "INFO" "XX is true"
           fn_writeResultFile "${RESULT_FILE}" "device is have info" "pass"
	else
           PRINT_LOG "FATAL" "XX is not true"
           fn_writeResultFile "${RESULT_FILE}" "device is not have info" "fail"

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
    rm -rf kk.txt iflog.txt network.txt
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


