#!/bin/bash

###############################################################################
#用例名称：config_valn（配置VLAN）
#用例功能：给所有的网口配置VLAN
#作者：mwx547872
#完成时间：2019-1-22
#前置条件：
#   OS系统正常启动
#测试步骤：
# 1. os下查询到所有网口的名字
# 2. 给所有的网口配置2个VLAN
# 3. 给VLAN配置IP
# 4. 删除VLAN
#测试结果
# 可以正常配置VLAN，配置VLAN IP ,成功删除VALN
################################################################################
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

#存放每个测试步骤执行结果
RESULT_FILE=${TMPDIR}/${test_name}.result
test_result="pass"


################判断是否在root下面执行用例#############
function init_env(){
   fn_checkResultFile ${RESULT_FILE}
   if [ `whoami` != 'root' ]
   then
     echo "You must be root user " >$2
     exit 1
   fi
   yum install vconfig -y
}
##********************************************#
# Name          : get _network_name           #
# Description   : 获取网卡名字                #
                                              #
#*********************************************#
function get_network_name()
{

  ip link|grep "BROADCAST" > 1.log
  cat 1.log
  i=0
  while read line
  do
    str=`echo $line|awk '{print $2}'|sed 's/://g'|grep "e"`
    #echo $str
    echo $i
    array[$i]=${str}
    echo ${array[$i]}
    let i+=1
  done <  1.log
  echo ${array[@]}
  print_info $? get_network

}


##*********************************************#
# Name        : config_network_Vlan            #
# Description : 给所有网口配置VLAN             #
# Parameter   ： 无                            #
#**********************************************#
function config_network_vlan()
{
       for var in ${array[@]}

      do
         echo $var

         vconfig add $var 100
         ip address add dev $var.100 192.168.1.26/24 dev $var.100
         vconfig add $var 200
         ip address add dev $var.200 192.168.1.27/24 dev $var.100

      done

      print_info $? config_network
}

#**********************************************#
# Name        : delete_network_vlan            #
# Description : 删除配置的VLAN                 #
# Parameter   ：   无                            #
#**********************************************#
function delete_network_vlan()
{

       for var in ${array[@]}

      do
         vconfig rem  $var.100
         vconfig rem $var.200

      done

      print_info $? delete_vconfig
}
init_env
get_network_name
config_network_vlan
delete_network_vlan
