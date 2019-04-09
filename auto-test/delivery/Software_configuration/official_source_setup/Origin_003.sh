#!/bin/bash

#*****************************************************************************************
# *用例名称：Origin_003
# *用例功能: RHEL官方源搭建
# *作者：mwx547872
# *完成时间：2019-2-21
# *前置条件：
#   1、预装redhat操作系统
# *测试步骤：
#   1、 进入redhat操作系统。
#   2.  使用修改源
# *测试结果：
#  可以执行yum --noplugins list命令列出软件包
#  yum --noplugins update命令执行成功
#*****************************************************************************************
set -x
#加载公共函数
. ../../../../utils/test_case_common.inc
. ../../../../utils/error_code.inc
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
        #判断是否为root用户
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
          "redhat")
          #下载redhat官方源 
          #wget -c ${ci_http_addr}/test_dependents/RHEL-8.0.0-20190228.1-aarch64-dvd1.iso
		   yum install wget -y
           wget http://10.90.31.177/business/redhat/RedhatRHEL-8-0-0/RHEL-8.0.0-20190228.1-aarch64-dvd1.iso
          if [ $? -eq 0 ]
          then
              fn_writeResultFile "${RESULT_FILE}" "wget-rhel-iso" "pass"

              PRINT_LOG "INFO" "download redhat source iso success"

          else

              fn_writeResultFile "${RESULT_FILE}" "wget-rhel" "fail"

              PRINT_LOG "FAIL" "download redhat source iso  is fail"


          fi
          #在/mnt下面新建iso文件
           mkdir -p /mnt/cdrom

          #挂载镜像
           mount /root/RHEL-8.0.0-20190228.1-aarch64-dvd1.iso /mnt/cdrom
            if [ $? -eq 0 ]
           then
              fn_writeResultFile "${RESULT_FILE}" "mount-iso" "pass"

              PRINT_LOG "INFO" "mount rehel iso success"

           else

              fn_writeResultFile "${RESULT_FILE}" "mount-iso" "fail"

              PRINT_LOG "FAIL" "mount rehel iso is fail"


          fi

           #新建配置文件
	   cd /etc/yum.repos.d/
           touch rhel8dvd.repo
	   cd -
           #修改rhel7dvd.repo文件
	       echo "[rhel-baseos]" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "name=rhel8-baseos" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "baseurl=file:///mnt/cdrom/BaseOS" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "enable=1" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "gpgcheck=0" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "[rhel-appstream]" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "name=rhel8-stream" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "baseurl=file:///mnt/cdrom/AppStream" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "enable=1" >> /etc/yum.repos.d/rhel8dvd.repo
           echo "gpgcheck=0" >> /etc/yum.repos.d/rhel8dvd.repo

           #清除相关缓存
           yum clean all
           subscription-manager clean
           #执行yum --noplugins list观察结果
           yum --noplugins list|grep "Installed Packages"
           if [ $? -eq 0 ]
           then
              fn_writeResultFile "${RESULT_FILE}" "yum-list" "pass"

              PRINT_LOG "INFO" "yum --noplugins list success"

           else

              fn_writeResultFile "${RESULT_FILE}" "yum-list" "fail"

              PRINT_LOG "FAIL" "yum --noplugins list is fail"


          fi

           #执行yum --noplugins update观察操作结果
           yum --noplugins update
           if [ $? -eq 0 ]
           then
              fn_writeResultFile "${RESULT_FILE}" "yum-update" "pass"

              PRINT_LOG "INFO" "yum --noplugins update success"

           else

              fn_writeResultFile "${RESULT_FILE}" "yum-update" "fail"

              PRINT_LOG "FAIL" "yum --noplugins update is fail"


          fi


         ;;

          *)
              fn_writeResultFile "${RESUlt_FILE}" "disto-redhat" "fail"
              PRINT_LOG "WARING" "distro is not redhat"
              exit 1

           ;;

         esac
         check_result ${RESULT_FILE}



}
function clean_env()
{
       FUNC_CLEAN_TMP_FILE
      # rm -f RHEL-ALT-7.6-20181010.0-Server-aarch64-dvd1.iso
      # umount /mnt/cdrom
       #rm -rf cdrom
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
LAVA平台上报结果接口，勿修改
lava-test-case "$test_name" --result ${test_result}
exit ${ret}
