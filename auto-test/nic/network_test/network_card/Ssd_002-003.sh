#!/bin/bash

#*****************************************************************************************
# *用例名称：Ssd_002                                                      
# *用例功能：挂载ssd盘                                           
# *作者：lwx652446                                                                      
# *完成时间：2019-2-28                                                               
# *前置条件：                                                                            
#   1、D06服务器1台
#	2、单板中配置一个ssd盘
#	3、安装好suse操作系统                                                                 
# *测试步骤：                                                                               
#   1 登录操作系统
#	2 fdisk -l查看硬盘名称
#	3.fdisk /dev/xxx(硬盘名称)进入操作界面
#	4.输入n，回车创建分区，回车选择默认直到再次“command（m for help）”，输入w，回车保存
#	5.fdisk -l查看分区是否创建成功
#	6.mkfs.ext3 /dev/xxx(分区名)格式化分区
#	7.mkdir /fdisk 创建挂载目录
#	8.mount /dev/xxx(分区名) /fdisk 挂载分区    
# *测试结果：                                                                            
#   可以在fdisk目录下下进行文件创建、修改、删除操作                                                      
#*****************************************************************************************

#*****************************************************************************************
# *用例名称：Ssd_003                                                    
# *用例功能：卸载ssd盘                                           
# *作者：lwx652446                                                                      
# *完成时间：2019-2-28                                                               
# *前置条件：                                                                            
#   1、D06服务器1台
#	2、单板中配置一个ssd盘
#	3、安装好suse操作系统                                                                 
# *测试步骤：                                                                               
#   1 登录操作系统
#	2 挂载ssd盘
#	3 umount /dev/xxx(分区名) 卸载分区
#	4 mkfs.ext3 /dev/xxx(分区名) 格式化分区
#	5 fdisk /dev/xxx(硬盘名）进入操作界面
#	6 输入d，回车删除分区
#	7 删除完毕后输入w回车保存    
# *测试结果：                                                                            
#   lsblk和fdisk -l查不到对应硬盘分区                                                      
#*****************************************************************************************

#加载公共函数
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
test_result="pass"
disk_name=""
part_name=""

function mount_partition()
{
	#获取磁盘名
	disks=(`lsblk |grep disk|awk '{print $1}'`)
	
	for ((i=0;i<${#disks[@]};i++))
	do
		if df|grep ${disks[i]}
		then
		unset ${disks[i]}
		fi
	done

	disk_name=${disks[0]}

	#创建分区，保存日志结果。
	cat << EOF > new_part.inc
n



w

EOF

	cat new_part.inc| fdisk /dev/$disk_name > new_partition.log
	
	#获取新建分区的分区号
	partition_num=`cat new_partition.log |grep "Partition number"|awk -F "default " '{print $2}'|awk -F ")" '{print $1}'`
	part_name=$disk_name$partition_num

	lsblk|grep $part_name
	if [ $? -ne 0 ]
	then
		PRINT_LOG "FATAL" "Failed to create partition,Program exit,Please check it." 
		fn_writeResultFile "${RESULT_FILE}" "Create partition" "fail"
		return 1
	else
		PRINT_LOG "INFO" "Create partition pass" 
		fn_writeResultFile "${RESULT_FILE}" "Create partition" "pass"
	fi
	
	#格式化分区,挂载分区
	mkfs.ext3 /dev/$part_name
	mkdir /fdisk
	mount /dev/$part_name /fdisk
	if [ $? -ne 0 ]
	then
		PRINT_LOG "FATAL" "Mounting partition failed,Program exit,Please check it." 
		fn_writeResultFile "${RESULT_FILE}" "Mounting partition" "fail"
		return 1
	else
		PRINT_LOG "INFO" "Mounting partition pass" 
		fn_writeResultFile "${RESULT_FILE}" "Mounting partition" "pass"
	fi
}

function cud_file()
{
	cud=0
	#在fdisk目录下新增，修改，删除文件
	ls > /fdisk/test.txt
	if [ $? -ne 0 ]
	then
		PRINT_LOG "FATAL" "Create file failed" 
		fn_writeResultFile "${RESULT_FILE}" "Create file" "fail"
		cud=1
	fi
	
	echo modify test >> /fdisk/test.txt
	if [ $? -ne 0 ]
	then
		PRINT_LOG "FATAL" "Update file failed" 
		fn_writeResultFile "${RESULT_FILE}" "Update file" "fail"
		cud=1
	fi
	
	rm -rf /fdisk/test.txt
	if [ $? -ne 0 ]
	then
		PRINT_LOG "FATAL" "Delete file failed" 
		fn_writeResultFile "${RESULT_FILE}" "Delete file" "fail"
		cud=1
	fi
	
	if [ $cud -eq 0 ]
	then
		PRINT_LOG "INFO" "Create Update Delete file pass" 
		fn_writeResultFile "${RESULT_FILE}" "CUD file" "pass"
	fi
}

function unmount_partition()
{
	#卸载、格式化分区
	umount /dev/$part_name
	mkfs.ext3 /dev/$part_name
	
	#删除新建分区
	cat << EOF > del_part.inc
d

w

EOF
	
	cat del_part.inc|fdisk /dev/$disk_name

	#确保lablk、fdisk -l均查不到分区
	lsblk|grep $part_name || fdisk -l |grep $part_name
	if [ $? -eq 0 ]
	then
		PRINT_LOG "FATAL" "Failed to delete partition,Program exit,Please check it." 
		fn_writeResultFile "${RESULT_FILE}" "Delete partition" "fail"
	else
		PRINT_LOG "INFO" "Delete partition pass" 
		fn_writeResultFile "${RESULT_FILE}" "Delete partition" "pass"
	fi

}

#预置条件
function init_env()
{
  #检查结果文件是否存在，创建结果文件：
	fn_checkResultFile ${RESULT_FILE}
	
	#root用户执行
	if [ `whoami` != 'root' ]
	then
		PRINT_LOG "INFO" "You must be root user " 
		fn_writeResultFile "${RESULT_FILE}" "Run as root" "fail" 
		return 1
	fi
}

#测试执行
function test_case()
{
	#创建挂载分区
	mount_partition
	
	#创建、修改、删除文件
	cud_file
	
	#卸载删除分区
	unmount_partition
	
	#检查结果文件，根据测试选项结果，有一项为fail则修改test_result值为fail，
	check_result ${RESULT_FILE}
}

#恢复环境
function clean_env()
{
	#清除临时文件
	FUNC_CLEAN_TMP_FILE
	
	#删除日志、测试、配置文件
	rm -rf new_partition.log
	rm -rf /fdisk
	rm -rf new_part.inc
	rm -rf del_part.inc
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
