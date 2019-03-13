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
. ../../../utils/sys_info.sh
. ../../../utils/sh-test-lib      




#预置条件
function init_env()
{

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
	print_info 0 set_enable
else 
	print_info 1 set_enable	
fi


echo always > /sys/kernel/mm/transparent_hugepage/defrag

Defrag=`cat /sys/kernel/mm/transparent_hugepage/defrag |grep "[always]"`
if [[ "$Defrag" =~ "[always]" ]];then
	print_info 0 set_defrag
else
	print_info 1 set_defrag
fi

}




function main()
{
    init_env 
    test_case 
}

main 

























