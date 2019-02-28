#!/bin/bash

#######################################
#Tools for Backup mysql,Using xtrabackup
#@author zhaoxintao
#@date 2018/11/02
#######################################

echo ===========================================
echo ===name:autobackup.sh======================
echo ===Desc: for mysql auto backup=============
echo ===File autobackup.conf Needed=============
echo ===usage:./autobackup.sh 1: full backup====
echo ===usage:./autobackup.sh 2: ince backup====
echo ===Auth by Eric.zhao=======================
echo ===`date`=============
echo ===========================================
echo #

v_exitflag=0
v_ct=$#
v_backuptype=$1

envcheck()
{

cd `dirname $0`

if [ ! -f ./autobackup.conf ]
then
  echo "Error:NO configure file 'autobackup.conf' found!"
  v_exitflag=1
fi

if [ $v_ct -lt 1 ]
then
  echo "Error: usage: autobackup.sh backuptype,which backuptype:1 means fullbackup;2 means incre"
  v_exitflag=1
  errorexit
fi

which innobackupex
if [ $? -ne 0 ]
then
  echo "Error: NO xtrabackup env found, setup xtrabackup first! or add xtrabackup's bin dir to path.."
  v_exitflag=1
fi

if [ $v_backuptype -eq 1 ]
then
  echo INFO: Begin to execute full backup...
  v_backup=1
else
  v_scn1=`grep fullscn autobackup.conf|awk -F : '{print $2}'`
  v_scn2=`grep incrscn autobackup.conf|awk -F : '{print $2}'`
  v_backup=2

  if [ -z $v_scn2 ]
  then
     if [ -z $v_scn1 ]
     then
     echo "Error: No full backup record found,Full backup first!!"
     v_exitflag=1
     errorexit
     else
     echo "INFO: Begin to increbackup using full backup scn:$v_scn1"
     v_scn=$v_scn1
     fi
  else
     echo "INFO: Begin to increbackup using last increbackup scn:$v_scn2"
     v_scn=$v_scn2
  fi
fi


errorexit
}


execbackup()
{
 v_date=`date +%Y%m%d%H%M%S`
 ./execbackup.sh $v_backuptype $v_scn > logs/backup_${v_date}.log 2>&1
}


scnrecord()
{
  v_success=`grep successflag autobackup.conf|awk -F : '{print $2}'`
  if [ $v_success -eq 0 ]
  then
    v_nscn=`grep "xtrabackup: Transaction log of" ./logs/backup_${v_date}.log |awk -F '(' '{print $2}'|awk -F ')' '{print $1}'`
    if [ ! -n $v_nscn ]
    then
      echo Error: Backup finished with errors, NO SCN found, Check logfile for detail..
    else 
      if [ $v_backuptype -eq 1 ]
      then
        sed -i 's/fullscn.*/fullscn:'${v_nscn}'/g' ./autobackup.conf
        sed -i 's/incrscn.*/incrscn:/g' ./autobackup.conf
      else
        sed -i 's/incrscn.*/incrscn:'${v_nscn}'/g' ./autobackup.conf
      fi
      echo INFO: Backup finished Successfull!!
    fi
  else
    echo Error: Some errors found,Check logfile for detail..
  fi
}

errorexit()
{
if [ $v_exitflag -gt 0 ]
then
  exit 0
fi
}


envcheck
execbackup
scnrecord
