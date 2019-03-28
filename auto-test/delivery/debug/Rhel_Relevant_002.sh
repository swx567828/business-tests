#!/bin/bash

#*****************************************************************************************
# *用例名称：Suse_Relevant_005
# *用例功能: 查看系统是否能安装java
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
set -x
#加载公共函数
. ../../../utils/test_case_common.inc
. ../../../utils/error_code.inc
#. ../../../utils/sys_info.sh
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
#	fn_checkResultFile ${RESULT_FILE}
        if [ `whoami` != 'root' ]; then
            echo "You must be the superuser to run this script" > $2
            exit 1
        fi
}

#测试执行
function test_case()
{
	check_result ${RESULT_FILE}
        fn_get_os_type distro_type
        case $distro_type in
           "ubuntu" | "debian" )
          apt-get install javacc -y
        #  print_info $? install-gcc
          if [ $? -eq 0 ]
          then
              fn_writeResultFile "${RESULT_FILE}" "install-gcc" "pass"
              PRINT_LOG "INFO" "install gcc package is success"
 #             print_info 0 install-gcc
          else
              fn_writeResultFile "${RESULT_FILE}" "install-gcc" "fail"
              PRINT_LOG "INFO" "install gcc package is fail"
  #           print_info 1 install-gcc
          fi
          ;;


         "centos" | "redhat" )
          echo 111111111111111111111111
          yum install java-1.8.0-openjdk -y
          if [ $? -eq 0 ]
          then
               fn_writeResultFile "${RESULT_FILE}" "install-gcc" "pass"

              PRINT_LOG "INFO" "install gcc package is success"

             # print_info 0 install-gcc

          else

              fn_writeResultFile "${RESULT_FILE}" "install-gcc" "fail"

              PRINT_LOG "INFO" "install gcc package is fail"


             # print_info 1 install-gcc


          fi
          ;;

          "suse")
           zypper install -y java-1_8_0-openjdk
          if [ $? -eq 0 ]

          then

               fn_writeResultFile "${RESULT_FILE}" "install-gcc" "pass"

              PRINT_LOG "INFO" "install gcc package is success"

             # print_info 0 install-gcc

          else

              fn_writeResultFile "${RESULT_FILE}" "install-gcc" "fail"

              PRINT_LOG "INFO" "install gcc package is fail"


#              print_info 1 install-gcc
           fi
           ;;

         esac
         check_result ${RESULT_FILE}



}
function clean_env()
{
       FUNC_CLEAN_TMP_FILE
     	case $distro_type in
       "ubuntu|debian")
           apt-get remove javacc  -y
        ;;
       "centos"|"redhat")
           yum remove -y java-1.8.0-openjdk
        ;;
      "suse")
           zypper remove -y java-1_8_0-openjdk
       ;;
    esac

}

function main()
{
init_env|| test_result="fail"
        if [ ${test_result} = "pass" ]
        then

        test_case || test_result="fail"
       fi
        clean_env || test_result="fail"
        [ "${test_result}" = "pass" ] || return 1

}

main
ret=$?
#LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
