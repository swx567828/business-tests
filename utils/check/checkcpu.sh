#!/bin/bash
err=0
mode=0
if [ ! -e cpuinfo.prd ]
then 
	mode=1
fi
core_num=`cat /proc/cpuinfo | grep -c processor`

if [ $mode -eq 1 ]
then
	echo "Corenum $core_num" > cpuinfo.prd
	err=0
else
	corenum_prd=`grep "Corenum" cpuinfo.prd | awk '{print $2}'`
#	echo "$corenum_prd"
	if [ $core_num -eq $corenum_prd ]
	then
		err=0
    echo "Check CPU OK !" > checkcpu_result.log
	else
		dateinfo=`date +%m_%d_%T`
		#if [ $core_num -ne $corenum_prd ]
			err=1
			echo "Check CPU Fail , reason : -> $dateinfo Core number $corenum_prd" > checkcpu_result.log
			echo "The old core number is $core_num and the new one is $corenum_prd">> checkcpu_result.log
		fi

cat checkcpu_result.log
exit $err
fi
