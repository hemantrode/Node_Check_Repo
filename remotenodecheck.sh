#!/bin/bash
# 
#file name : remotenodecheck.sh
chk_db_status() {
#ps -ef | grep pmon | awk -F_ '{print $(NF -0)}' | grep -v grep | grep -v +ASM | while read inst_name
cat ${v_file_nm} | grep '^DB' | grep -v grep | grep -v +ASM  > /tmp/tmp_db
while read readtype instname
do
	inst_present=`ps -ef | grep pmon | grep ${instname} | wc -l`
	if [[ ${inst_present} -eq 1  ]]	
	then
		export ORACLE_SID=${instname}
		export ORAENV_ASK=NO
		. /usr/local/bin/oraenv
		echo Oracle Home is: $ORACLE_HOME
		#. /usr/local/bin/oraenv 
		dbstatus=`$ORACLE_HOME/bin/sqlplus -silent "/ as sysdba"  <<-EOFSQL
		set pagesize 0 feedback off verify off heading off echo off;
		select name from v\\$database where OPEN_MODE ='READ WRITE';
		exit;
		EOFSQL`

		if [[ -z ${dbstatus} ]]
		then 
		echo " ${instname} on ${v_hstname} in file ${v_file_nm} Not in READ-WRITE mode"
		fi
	else
		echo " ${instname} on ${v_hstname} in file ${v_file_nm} is NOT Up. Pmon process not present   "
	fi
done < /tmp/tmp_db
}


chk_lsn_status() {
cat ${v_file_nm} | grep '^LSN' | grep -v grep > /tmp/tmp_lsn
while read readtype lsn_name
do
        lsn_present=`ps -ef | grep -wi ${lsn_name} | grep -v grep| wc -l`
        #echo  "lsncnt_= "${lsn_present}
        if [[ ${lsn_present} -eq 1  ]]
        then
                echo " ${lsn_name} process preesent on ${v_hstname} in file ${v_file_nm} "
        else
                echo " ${lsn_name} process NOT present on ${v_hstname} "
        fi
done < /tmp/tmp_lsn
}


chk_nfs_mounpoint() {
cat ${v_file_nm} | grep '^NFS' | grep -v grep > /tmp/tmp_nfs
while read readtype nfs_name
do
        nfs_present=`df -h | grep -wi ${nfs_name} | grep -v grep| wc -l`
        #echo  "nfscnt_= "${nfs_present}
        if [[ ${nfs_present} -eq 1  ]]
        then
                echo " ${nfs_name} mountpoint preesent on ${v_hstname} in file ${v_file_nm} "
        else
                echo " ${nfs_name} mountpoint
		NOT present on ${v_hstname} "
        fi
done < /tmp/tmp_nfs
}




##main
. ~/.profile
. ~/.bash_profile
echo "Remote script on remote server is:" $scrname
osname=`uname -a | awk -F" " '{print $1}'`
echo ${imsg} osname is: $osname
PATH=${PATH}:/usr/local/lang/bin/
echo Path is: ${PATH}
if [ -z "${osname}" ] ; then
        echo ${fmsg} "osname could not be determined"
        handleError 1 M
fi

case $osname in
  "HP-UX" ) oratabpath="/etc/oratab"
    ;;
  "SunOS" ) oratabpath="/var/opt/oracle/oratab"
    ;;
  "Linux" ) oratabpath="/etc/oratab"
    ;;
  * ) oratabpath="/etc/oratab"
    ;;
esac

v_hstname=`hostname`
v_file_nm=bbcexdrtw001db03.bbc.local.txt
chk_db_status
chk_lsn_status
chk_nfs_mounpoint

-----------------------------------------
File 
bbcexdrtw001db03.bbc.local.txt
DB	FTEST1
DB	OPRD1
DB	DUMMY
DB	CMODPROF
LSN     LISTENER1
NFS     /siebel/v11/fs


