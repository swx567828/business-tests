#!/bin/bash
set -x

#*****************************************************************************************
# *用例编号：Performance2_004                                                        
# *用例名称：对齐性能标杆参数：stream-1C stream-2P                                              
# *作者：dwx588814                                                                       
# *完成时间：2019-02-21                                                                   
# *前置条件：                                                                            
#   1、D06服务器1台
#   2、bios关闭smmu和ras
#   3、透明页模式设置为always：
#   echo always > /sys/kernel/mm/transparent_hugepage/enabled；
#   echo always > /sys/kernel/mm/transparent_hugepage/defrag
#   4、获取测试套压缩文件/opt/linaro-rp/sailing/ubuntu/test-tool/1620check.tar并解压到服务器的root用户下                                                                
# *测试步骤：                                                                               
#   1 按解压后目录下的readme.txt进行操作收集stream-1C和stream-2P数据
#   2 检查收集stream-1C和stream-2P的数据是否符合需求
# *测试结果：
#   收集到stream-1C和stream-2P的数据符合要求
#**********************************************************************************

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

#安装依赖包
case "$distro" in
    centos|redhat)
	yum install wget gcc make gcc gcc-c++ -y
	;;
    debian|ubuntu)
	apt install wget gcc g++ make -y
	;;
    suse)
	zyyper install -y wget gcc gcc-c+ make 
	;;
esac

if [ $? -eq 0 ];then
	echo "install deps-package pass"

else
	echo "install deps-package failed"

fi


#获取测试套压缩文件
if [ -d "1620check/" ];then
	rm -rf 1620check/
fi

wget  ${ci_http_addr}/test_dependents/1620check.tar
tar xf 1620check.tar 

}


#测试执行
function test_case()
{

#修改文件执行权限
file1="1620check/specint-ubuntu/400.perlbench/perlbench_base.d06-ubuntu"
file2="1620check/specint-ubuntu/462.libquantum/libquantum_base.d06-ubuntu"
file3="1620check/specint-ubuntu/400-462.sh"
file4="1620check/specint-ubuntu/arm_log_process.py"
file5="1620check/specint-ubuntu/run-test.sh"

for i in $file1 $file2 $file3 $file4 $file5
do
	if [ ! -x "$i" ];then
		chmod 777 $i
	fi
done

#执行脚本run-test.sh
cd 1620check/specint-ubuntu/
source run-test.sh > run.log
cat run.log
grep "end of file!" run.log
print_info $? run-test

cd ../

#执行stream-process.py
python stream-process.py stream-gcc730-static/over_test.log > stream-process.log
cat stream-process.log
egrep "1c-result|2P-result" stream-process.log
print_info $? stream-process

cd ../
}


#恢复环境
function clean_env()
{
  rm -rf 1620check.tar
}


function main()
{
    init_env 
    test_case 
    clean_env 
}

main 





























































