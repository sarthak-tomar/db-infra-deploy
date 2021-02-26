#!/bin/bash

# Database credentials
user="Backup"
password='B@ckUp-$F-N0k!@'
host1="172.31.10.28"
host2="172.31.12.98"
HAhost="127.0.0.1"
port="3355"
client="Nokia-Latin"

## CHECK Mysql Heartbeat
beat1=$(mysqladmin --user=${user} --password=${password} --host=$host1  --ssl --port=$port ping)
if [ "$beat1" != "mysqld is alive" ];
then
echo " $client Production Master-Database-1 ( $host1 ) is down. Please Check ASAP " | mailx -v  -s "$client DB Mysql Server Down "  "sarthak.tomar@innoeye.com  ,piyush.diwakar@innoeye.com ,  vipul.choure@innoeye.com , rohit.saraf@innoeye.com, prateek.chauhan@innoeye.com  ";
fi

beat2=$(mysqladmin --user=${user} --password=${password} --host=$host2  --ssl --port=$port ping)
if [ "$beat2" != "mysqld is alive" ];
then
echo " $client Production Master-Database-2 ( $host2 ) is down. Please Check ASAP " | mailx -v   -s "$client DB Mysql Server Down "  "sarthak.tomar@innoeye.com, piyush.diwakar@innoeye.com ,  vipul.choure@innoeye.com , rohit.saraf@innoeye.com  , prateek.chauhan@innoeye.com ";
fi

#REPLICATION STATUS
echo "`date`
 ------------ CHECKING Replication STATUS ----------------";

status1="`mysql --user=${user} --password=${password} --host=$host1  --port=$port --ssl -e 'SHOW SLAVE STATUS\G;' | grep Last_IO_Errno | grep -o -E '[0-9]+' `";
error_message1="`mysql --user=${user} --password=${password} --host=$host1 --port=$port  -e 'SHOW SLAVE STATUS\G;' | grep Last_IO_Error ` "

if [ "${status1}" != "0" ] ; then
echo "Master DB 2 Replication Status $host1 : ${status1}"$'\n'"  ${error_message1}  "$'\n' $'\n' $'\n' " "  | mailx -v -b "piyush.diwakar@innoeye.com" -s "$client DB REPLICATION FAILED"  "sarthak.tomar@innoeye.com"
fi

status2="`mysql --user=${user} --password=${password} --host=$host2  --port=$port --ssl -e 'SHOW SLAVE STATUS\G;' | grep Last_SQL_Errno |grep -o -E '[0-9]+'`";
error_message2="`mysql --user=${user} --password=${password} --host=$host2  --port=$port  -e 'SHOW SLAVE STATUS\G;' | grep Last_SQL_Error`"

if [ "${status2}" != "0" ] ; then
echo "Master DB 1 Replication Status $host2 : ${status1}"$'\n'"ERROR MESSAGE :   ${error_message1}  "$'\n' $'\n' $'\n'" "  | mailx -v -b "    piyush.diwakar@innoeye.com " -s "$client DB REPLICATION FAILED"  "sarthak.tomar@innoeye.com"
fi

##HAPROXY STATUS

echo "`date`
------------ CHECKING HAPROXY STATUS ----------------";

for i in `seq 1 3` 
do
temp=$(mysql   --user=${user} --password=${password}  --port=$port --host=$HAhost --ssl -e "show variables like 'server_id'" -B | sed 's/[^0-9]//g')
if [ ${temp} -eq 2 ] ; then
echo "HAPROXY Switched to MasterDB-2  ON HOST $host2"$'\n' $'\n'"MasterDB-1 Replication Status $host1 : ${status1}"$'\n'"ERROR MESSAGE :   ${error_message1}  "$'\n' $'\n' $'\n'"MasterDB-2 Replication Status host2 : ${status2} "$'\n'"ERROR MESSAGE :   ${error_message2} "   | mailx -v   -s "$client DB SERVER HAPROXY STATUS" "sarthak.tomar@innoeye.com, piyush.diwakar@innoeye.com ,  vipul.choure@innoeye.com ,prateek.chauhan@innoeye.com, rohit.saraf@innoeye.com";
fi
done

## Replication-Lag

seconds_behind_master1="`mysql --user=${user} --password=${password} --host=$host1   --port=$port --ssl  -e 'SHOW SLAVE STATUS\G;' | grep Seconds_Behind_Master | grep -o -E '[0-9]+'`"

if [ "$seconds_behind_master1" -gt 60 ] ; then
echo " $client Production  Slave is ${seconds_behind_master1}  SECOND BEHIND Master.  Please Check Slave Replication Lag ASAP.   "$'\n' $'\n'"Seconds_Behind_Master : ${seconds_behind_master1} " | mailx -v    -s "$client-PROD Mysql Replication Lag "  " sarthak.tomar@innoeye.com,  piyush.diwakar@innoeye.com, vipul.choure@innoeye.com , rohit.saraf@innoeye.com ,prateek.chauhan@innoeye.com  ";
fi

seconds_behind_master2="`mysql --user=${user} --password=${password} --host=$host2   --port=$port --ssl  -e 'SHOW SLAVE STATUS\G;' | grep Seconds_Behind_Master | grep -o -E '[0-9]+'`"

if [ "$seconds_behind_master2" -gt 60 ] ; then
echo " $client Production  Slave is ${seconds_behind_master2}  SECOND BEHIND Master.  Please Check Slave Replication Lag ASAP.   "$'\n' $'\n'"Seconds_Behind_Master : ${seconds_behind_master2} " | mailx -v    -s "$client-PROD Mysql Replication Lag"  " sarthak.tomar@innoeye.com,  piyush.diwakar@innoeye.com ,  vipul.choure@innoeye.com , rohit.saraf@innoeye.com ,prateek.chauhan@innoeye.com  ";
fi


## MAX-CONNECTION-ALERT
conn=`mysql  --user=${user} --password=${password} --host=$HAhost  --port=$port --ssl -e "select count(*) as Max_used_connections   from  information_schema.PROCESSLIST where USER not in ('system user','replication','event_scheduler') \G; " | grep Max_used_connections | grep -o -E '[0-9]+'`;
if [ "$conn" -gt 200 ] ; then
echo " $client Production reached Too many connections. Please Check ASAP   "$'\n' $'\n'"Max_Used_Connections : ${conn} " | mailx -v    -s  "$client-Production Mysql TOO MANY CONNECTIONS "  " sarthak.tomar@innoeye.com, piyush.diwakar@innoeye.com ,  vipul.choure@innoeye.com , rohit.saraf@innoeye.com, prateek.chauhan@innoeye.com ";
fi

## USER-PASSWORD-EXPIRED

hourly=$(date +'%H:%M')
expire_date=$(date -d "+3 days")
if [ "$hourly" == "10:15" ] ; then

db_user=`echo " select  distinct user  from sys.innodb_expire  where user not in ('mysql.session','mysql.sys') and password_lifetime is not null; " | mysql  --user=${user} --password=${password} --host=$host1  --port=$port --ssl   -B | sed /^user$/d`
curr_date=`mysql --user=${user} --password=${password} --host=$host1  --port=$port --ssl -e "select  date(now()) as CURR_DATE \G;" | grep  CURR_DATE | cut  -d ':' -f 2`

for DB in $db_user
do
expiry_date=`mysql --user=${user} --password=${password} --host=$HAhost  --port=$port --ssl  -e "select   max(date(password_last_changed + interval password_lifetime-3 day )) as EXPIRY_DATE from sys.innodb_expire  where  password_lifetime is not null  and  user = '$DB'   group by user \G;" | grep EXPIRY_DATE | cut  -d ':' -f 2`
if [ "$expiry_date" == "$curr_date" ] ; then
echo " $client Production DB user $DB Expires in 3 days. Please Update $DB User Password ASAP.   "$'\n' $'\n'"EXPIRY DATE : ${expire_date} " | mailx -v  -s "[URGENT] $client PRODUCTION : Password Expire "  " sarthak.tomar@innoeye.com, piyush.diwakar@innoeye.com ,  vipul.choure@innoeye.com , rohit.saraf@innoeye.com , prateek.chauhan@innoeye.com"
else
echo "$DB";
fi
done

fi;

