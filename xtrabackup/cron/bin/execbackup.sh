v_rip=`grep remoteip ./autobackup.conf|awk -F : '{print $2}'`
v_ruser=`grep remoteuser ./autobackup.conf|awk -F : '{print $2}'`
v_rdir=`grep remotedir ./autobackup.conf|awk -F : '{print $2}'`
v_lip=`grep localip ./autobackup.conf|awk -F : '{print $2}'`
v_ldbu=`grep localmysqluser ./autobackup.conf|awk -F : '{print $2}'`
v_ldbp=`grep localmysqlpass ./autobackup.conf|awk -F : '{print $2}'`

v_backuptype=$1

v_date=`date +%Y%m%d%H%M%S`

execfullbackup()
{
  innobackupex --host=$v_lip --user=$v_ldbu --password=$v_ldbp --stream=tar ./ | ssh $v_ruser@$v_rip \ "cat - > $v_rdir/mysql_${v_lip}_${v_date}_full.tar"
  if [ $? -ne 0 ]
  then
    echo "Error: Some errors found,Check logfile for detail.."
    sed -i 's/successflag.*/successflag:1/g' ./autobackup.conf
  else
    echo "INFO: Buckup finished Successfull!!"
    sed -i 's/successflag.*/successflag:0/g' ./autobackup.conf
  fi
}

execincebackup()
{
  innobackupex --host=$v_lip --user=$v_ldbu --password=$v_ldbp --incremental  --incremental-lsn=$v_lastscn --stream=xbstream ./ | ssh $v_ruser@$v_rip \ "cat - > $v_rdir/mysql_${v_lip}_${v_date}_incr.xbstream"
  if [ $? -ne 0 ]
  then
    sed -i 's/successflag.*/successflag:1/g' ./autobackup.conf
  else
    sed -i 's/successflag.*/successflag:0/g' ./autobackup.conf
  fi
}

if [ $v_backuptype -eq 1 ]
then
  execfullbackup
else
  v_lastscn=$2
  execincebackup
fi
