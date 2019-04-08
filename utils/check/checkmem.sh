#!/bin/bash
err=0
mode=0
#bladeinfo_memok=`grep "MEMSIZE" meminfo.prd`
if [ ! -e meminfo.prd1 -o ! -e meminfo.prd2 ]
#echo "$?"
then 
	mode=1
fi

memsize=`cat /proc/meminfo | grep "MemTotal" | awk '{print $2}'`
dimmsn=`dmidecode -t memory | grep "Serial Number" | awk '{print $3}'`
#echo "$memsize"
#echo "$dimmsn"
if [ $mode -eq 1 ]
then
	echo "$memsize" > meminfo.prd1
	echo "$dimmsn" > meminfo.prd2
	err=0
 # echo "check memory OK !" > result.log
else
#	temp=`grep "MemTotal" meminfo.prd1`
      #  memsize_prd=`echo ${temp#*}`
         memsize_prd=`grep -v "#" meminfo.prd1`
 #       echo "$memsize_prd"
	dimmsn_prd=`grep -v "#" meminfo.prd2`
  #      echo "$dimmsn_prd"
	if [ "$memsize" == "$memsize_prd" ] && [ "$dimmsn" == "$dimmsn_prd" ] 
        #if [ "$memsize" == "$memsize_prd" ]
        #if [ "$dimmsn" == "$dimmsn_prd" ]	
       then
		err=0
    echo "check memory OK !" > checkmem_result.log
        
	else
		if [ "$memsize" != "$memsize_prd" ]
		then
			err=1
			dateinfo=`date +%m_%d_%T`
            echo "$dateinfo Check Memory Fail: ERROR:1 ->  memory size $memsize" >> checkmem_result.log
			echo "The new memsize is $memsize old memsize is $memsize_prd" >> checkmem_result.log
              # exit $err
		fi
		if [ "$dimmsn" != "$dimmsn_prd" ]
		then
			err=2
            dateinfo=`date +%m_%d_%T`
            echo "$dateinfo Check memory Fail :ERROR:2 ->  memory dimm number $dimmsn" >> checkmem_result.log
			echo "The new memdimm num : $dimmsn  Old memdimm num : $dimmsn_prd" >> checkmem_result.log
           # exit $err
            fi

	fi
cat checkmem_result.log
exit $err
fi
