#!/bin/bash

#autor:  wangqiang
#date:2013-8-8

err=0
mode=0
dateinfo=`date +%m_%d_%T`
if [ ! -e pciinfo.txt ]
then
#echo $?
mode=1
fi
readpci=`lspci`
#echo $?
if [ $? -ne 0 ]
then 
echo "read pci info fail!pls retry!"
err=2
exit $err
fi
#echo "$readpci"
if [ $mode -eq 1 ]
then
echo "$readpci" > pciinfo.txt
#cat pciinfo.txt
err=0
else
echo "$readpci" > pciinfo.txt1
#cat pciinfo.txt1
diff -u pciinfo.txt pciinfo.txt1 > pcidiff.txt
#cat pcidiff.txt
#echo $?
if [ $? -ne 0 ]
then
err=1
echo "$dateinfo check pci fail,info does not match! detail diff pls refer to pcidiff.txt1" > checkpci_result.log
cat checkpci_result.log
exit $err
fi
echo "check pci OK!" > checkpci_result.log
cat checkpci_result.log
exit $err
fi

