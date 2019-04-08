#!/bin/bash
err=0
mode=0
couter=1
#bladeinfook=`grep "Disk" diskinfo.prd1`
#if [ $? -ne 0 ]
if [ ! -e diskinfo.prd1 -o ! -e diskinfo.prd2 ]
then 
	mode=1
fi
disknum=`fdisk -l |grep -c "Disk /dev/sd"`
diskcap=`fdisk -l  | grep "Disk /dev/sd" | awk '{print $5}'`
#echo "$disknum"
if [ $mode -eq 1 ]
then
	echo "Disk $disknum" > diskinfo.prd1
        echo "$diskcap" > diskinfo.prd2
	err=0	
else
      disknum_prd=`grep Disk diskinfo.prd1 | awk '{print $2}'`
      diskcap_prd=`cat diskinfo.prd2`
 #      echo "$diskcap_prd"
       #temp=`grep -v "#" diskinfo.prd2 | grep "Disk /dev/sd"`
       # diskcap_prd=`echo ${temp#*}`
       # echo "$diskcap_prd"
        #if [ $disknum -eq $disknum_prd ] && [ $diskcap -eq $host ]
       #if [ $disknum -eq $disknum_prd ]	
       if [ "$diskcap" == "$diskcap_prd" ] && [ "$disknum" == "$disknum_prd" ]
        then
        echo -e "check hdd OK!" > checkhdd_result.log
        else
        if [ "$disknum" != "$disknum_prd" ]
       then 
        err=1
        nowdate=`date +%m_%d_%T`
       echo "$nowdate check hdd fail,old hdd num is $disknum_prd, now is $disknum" >> checkhdd_result.log
       fi
      if [ "$diskcap" != "$diskcap_prd" ]
      then
       err=2
       echo "$nowdate old hdd cap is $diskcap_prd, now is $diskcap" >> checkhdd_result.log	
       fi
        fi 
       cat checkhdd_result.log
       exit $err
fi
