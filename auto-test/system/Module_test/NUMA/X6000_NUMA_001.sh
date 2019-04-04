#!/bin/bash

#*****************************************************************************************
# *用例名称：X6000_NUMA_001                                                         
# *用例功能：NUMA节点测试                                                
# *作者：lwx637528                                                                       
# *完成时间：2019-1-22                                                                   
# *前置条件：     
#       已安装OS
# *前置条件：                                                                   
#   1、配置yum源，安装numactl命令
#   2、numactl –H查看NUMA节点情况
#  
# *测试结果：                                                                            
#   A)、可见4个NUMA节点，每个节点下16（D05）/24个核（D06）                                                       
#*****************************************************************************************

#加载公共函数
. ../../../../utils/error_code.inc
. ../../../../utils/test_case_common.inc
. ../../../../utils/sys_info.sh
. ../../../../utils/sh-test-lib
#. ./utils/error_code.inc
#. ./utils/test_case_common.inc 

#获取脚本名称作为测试用例名称
test_name=$(basename $0 | sed -e 's/\.sh//')
#创建log目录
TMPDIR=./logs/temp
mkdir -p ${TMPDIR}
#存放脚本处理中间状态/值等
TMPFILE=${TMPDIR}/${test_name}.tmp
#存放每个测试步骤的执行结果
RESULT_FILE=${TMPDIR}/${test_name}.result

#自定义变量区域（可选）
#var_name1="xxxx"
#var_name2="xxxx"
test_result="pass"

#自定义函数区域（可选）
#*************************************************************
#Name         :distro_name                                   *
#Description  :check the os-name                             *
#Parameters   :NO                                            *
#*************************************************************


function distro_name()
{
distro=""
#sys_info=$(uname -a)
sys_info=$(cat /etc/os-release | grep PRETTY_NAME)

if [ "$(echo $sys_info |grep -E 'UBUNTU|Ubuntu|ubuntu')"x != ""x ]; then
    distro="ubuntu"
elif [ "$(echo $sys_info |grep -E 'cent|CentOS|centos')"x != ""x ]; then
    distro="centos"
elif [ "$(echo $sys_info |grep -E 'fed|Fedora|fedora')"x != ""x ]; then
    distro="fedora"
elif [ "$(echo $sys_info |grep -E 'Red Hat|Red')"x != ""x ]; then
    distro="redhat"
elif [ "$(echo $sys_info |grep -E 'DEB|Deb|deb')"x != ""x ]; then
    distro="debian"
elif [ "$(echo $sys_info |grep -E 'OPENSUSE|OpenSuse|opensuse|openSUSE')"x != ""x ]; then
    distro="opensuse"
elif [ "$(echo $sys_info |grep -E 'SUSE|Suse|suse|SUSE')"x != ""x ]; then
    distro="suse"
else
    distro="ubuntu"
fi
}



#*************************************************************
#Name         :install_deps                                  *
#Description  :install package                               *
#Parameters   :NO                                            *
#*************************************************************


install_deps() {
    pkgs="$1"
    [ -z "${pkgs}" ] && PRINT_LOG "INFO" "Usage: install_deps pkgs"
    # skip_install parmater is optional.
    skip_install="$2"
    let i=0

    if [ "${skip_install}" = "True" ] || [ "${skip_install}" = "true" ]; then
        PRINT_LOG "INFO" "install_deps skipped"
    else
        ! check_root && \
        PRINT_LOG "FATAL" "About to install packages, please run this script as root."
        PRINT_LOG "INFO" "Installing ${pkgs}"
        distro_name
        case "${distro}" in
          debian|ubuntu)
            # Use the default answers for all questions.
            DEBIAN_FRONTEND=noninteractive apt-get update -q -y
            # shellcheck disable=SC2086
            while (( $i < 5 )); do
                DEBIAN_FRONTEND=noninteractive apt-get install -q -y ${pkgs}
                if [ $? -eq 0 ]; then
                        break;
                fi
                let "i++"
                sleep 2
            done
            ;;
          centos)
            # shellcheck disable=SC2086
            while (( $i < 5 )); do
                yum -e 0 -y install ${pkgs}
                if [ $? -eq 0 ]; then
                    break;
                fi
                let "i++"
                sleep 2
            done
            ;;

	    redhat)
            # shellcheck disable=SC2086
            while (( $i < 5 )); do
                yum -e 0 -y install ${pkgs}
                if [ $? -eq 0 ]; then
                    break;
                fi
                let "i++"
                sleep 2
            done
            ;;

          fedora)
            # shellcheck disable=SC2086
            while (( $i < 5 )); do
                dnf -e 0 -y install ${pkgs}
                if [ $? -eq 0 ]; then
                        break;
                fi
                let "i++"
                sleep 2
            done
            ;;
           opensuse)
           while (($i <=5 ));do
              zypper install -y ${pkgs}
             if [ $? -eq 0 ]; then
                    break;
             fi
             let "i++"
             sleep 2
            done
            ;;
            suse)
           while (($i <=5 ));do
              zypper install -y ${pkgs}
             if [ $? -eq 0 ]; then
                    break;
             fi
             let "i++"
             sleep 2
            done
            ;;

          *)
            PRINT_LOG "WARN" "Unsupported distro: ${distro}! Package installation skipped."
	    fn_writeResultFile "${RESULT_FILE}" "Package installation" "skipped"
            i=5
            ;;
        esac
        # shellcheck disable=SC2181
        if [ $? -ne 0 ]; then
            PRINT_LOG "FATAL" "Failed to install dependencies, exiting..."
            i=5
        fi
    fi

    if [ $i -ge 5 ]; then
            return 1
    fi
}

#传入两时间$1,$2, 判断是否一致
 
function numactl_install()
{
    PRINT_LOG "INFO" "Check numactl tool install"
    numactl -H > /dev/null 2>&1
    if [ $? -ne 0 ]
    then 
        PRINT_LOG "INFO" "start install numactl now"
        install_deps numactl
        numactl -H > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            PRINT_LOG "FATAL" " install  numactl fail,please check "
            fn_writeResultFile "${RESULT_FILE}" "numactl_install" "fail"
            return 1
        else
            PRINT_LOG "INFO" "numactl install success"
            fn_writeResultFile "${RESULT_FILE}" "numactl_install" "pass"
        fi  
    fi
    
}   

function numa_node_check()
{
    nums_info=$(numactl -H |head -1)
    nums=`numactl -H| head -1 |awk -F '[:| ]+' '{print $2}'`
    if [ ${nums} = 4 ]
    then
        PRINT_LOG "INFO" "NUMA codes_num is ${nums_info} "
        node_num=`numactl -H|grep cpus|wc -l`
        if [ ${node_num} = 4 ]
        then
            fn_writeResultFile "${RESULT_FILE}" "node_num" "pass"
            cores_info=`numactl -H`
            cores_num=$(numactl -H|grep cpus |awk -F ':' '{print $2 }'|wc -w)
            if [ ${cores_num} = 64 ]
            then
                for i in `seq ${node_num}`
                do
                    per_node_num=$(numactl -H|grep cpus|sed -n "$i p" |awk -F ':' '{print $2 }'|wc -w)
                    if [ ${per_node_num} = 16 ]
                    then
                        PRINT_LOG "INFO" " per node ${per_node_num} success "
                        fn_writeResultFile "${RESULT_FILE}" "per_node_num" "pass"
                    else
                        PRINT_LOG "FATAL" " per node ${per_node_num} error "
                        fn_writeResultFile "${RESULT_FILE}" "per_node_num" "fail"
                        return 1
                    fi
                done
            elif [ ${cores_num} = 96 ]
            then
                for i in `seq ${node_num}`
                do
                    per_node_num=$(numactl -H|grep cpus|sed -n "$i p" |awk -F ':' '{print $2 }'|wc -w)
                    if [ ${per_node_num} = 24 ]
                    then
                        PRINT_LOG "INFO" " per node ${per_node_num} success "
                        fn_writeResultFile "${RESULT_FILE}" "per_node_num" "pass"
                    else
                        PRINT_LOG "FATAL" " per node ${per_node_num} error "
                        fn_writeResultFile "${RESULT_FILE}" "per_node_num" "fail"
                        return 1
                    fi
                done
			elif [ ${cores_num} = 128 ]
            then
                for i in `seq ${node_num}`
                do
                    per_node_num=$(numactl -H|grep cpus|sed -n "$i p" |awk -F ':' '{print $2 }'|wc -w)
                    if [ ${per_node_num} = 32 ]
                    then
                        PRINT_LOG "INFO" " per node ${per_node_num} success "
                        fn_writeResultFile "${RESULT_FILE}" "per_node_num" "pass"
                    else
                        PRINT_LOG "FATAL" " per node ${per_node_num} error "
                        fn_writeResultFile "${RESULT_FILE}" "per_node_num" "fail"
                        return 1
                    fi
                done
            else
                PRINT_LOG "FATAL" " core_num ${cores_num} error "
                fn_writeResultFile "${RESULT_FILE}" "cores_num" "fail"
                return 1
            fi
        else
            PRINT_LOG "FATAL" " node_num error ,test fail "
            fn_writeResultFile "${RESULT_FILE}" "node_num" "fail"
        fi  
    else
        PRINT_LOG "FATAL" " node_num error ,test fail "
        fn_writeResultFile "${RESULT_FILE}" "node_num" "fail"
    fi
}




function clean_tmp_file()
{
    if [ -e ${EXPECTLOG} ] 
    then    
        rm -f ${EXPECTLOG} 
        if [ $? -ne 0 ]
        then
            fn_writeResultFile "${RESULT_FILE}" "del_${EXPECTLOG}" "fail"
            return 1
        fi
    fi
    
    if [ -e ${TMPFILE} ] 
    then    
        rm -f ${TMPFILE} 
        if [ $? -ne 0 ]
        then
            fn_writeResultFile "${RESULT_FILE}" "del_${TMPFILE}" "fail"
            return 1
        fi
    fi
    
#[ -e ${TMPFILE} ] && rm -f ${TMPFILE} || fn_writeResultFile "${RESULT_FILE}" "del_${TMPFILE}" "fail"
}


#预置条件
function init_env()
{
  #检查结果文件是否存在，创建结果文件：
    fn_checkResultFile ${RESULT_FILE}
    #自定义测试预置条件检查实现部分：比如工具安装，检查多机互联情况，执行用户身份 
    #需要安装工具，使用公共函数install_deps，用法：install_deps "${pkgs}"
    #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
    numactl_install
}

#测试执行
function test_case()
{
    #测试步骤实现部分
    #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
    #记录每项测试结果，使用公共函数fn_writeResultFile，用法：fn_writeResultFile "${RESULT_FILE}" "test_item_name" "pass|fail"
    numa_node_check
    #检查结果文件，根据测试选项结果，有一项为fail则修改test_result值为fail，
    check_result ${RESULT_FILE}
}

#恢复环境
function clean_env()
{
    #清除临时文件
    FUNC_CLEAN_TMP_FILE
    #自定义环境恢复实现部分,工具安装不建议恢复
    #需要日志打印，使用公共函数PRINT_LOG，用法：PRINT_LOG "INFO|WARN|FATAL" "xxx"
    clean_tmp_file
    
}


function main()
{
    init_env || test_result="fail"
    if [ ${test_result} = 'pass' ]
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

