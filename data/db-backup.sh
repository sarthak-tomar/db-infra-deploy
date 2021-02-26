#!/bin/bash


#Database credentials
user="Backup"
password='B@ckUp-$F-N0k!@'
host1="172.31.14.235"
host2="172.31.11.228"
HAHost="127.0.0.1"
port="3355"
top_dir="/home/centos/appdata/DB-Backup/Daily"



#BACKUP DIRECTORY
backup_date=`date +%Y-%m-%d_%H:%M`
backup_dir="${top_dir}/${backup_date}"
echo "Backup directory: ${backup_dir}"
mkdir -p "${backup_dir}"
chmod 700 "${backup_dir}"

# Set default file permissions
umask 177

# Get MySQL databases
mysql_databases=`echo 'show databases' | mysql --user=${user} --password=${password} --host=$HAHost --port=$port --ssl    ${database} -B | sed /^Database$/d`


for database in $mysql_databases
do
 if [ "${database}" != "information_schema" ] && [ "${database}" != "performance_schema" ] && [ "${database}" != "sys" ] && [ "${database}" != "mysql" ]; then

 temp2=$temp2" Creating backup of \"${database}\" database
"
mysqldump --routines  --events --single-transaction --max-allowed-packet=1024M  --compress --quick   --user=$user --password=$password --host=$HAHost --port=$port --ssl    ${database} |  openssl  enc -aes-256-cbc -salt -out $backup_dir/${database}-$backup_date.sql.enc -k Admin@Nokia321

fi
done


#BACKUP COMPLETION TIME
echo  "BACKUP COMPLETED AT `date +%Y-%m-%d_%H:%M`";

#DELETE 3 DAYS OLD BACKUP

echo "before top_dir"
 cd $top_dir;
temp3="Deleting Backups
"
temp4="Remaining Backups
"
echo $top_dir;
        n=1;
        #echo "-------1"
        #ls

#        for f in `ls -t *.sql`
        for f in `ls -t $top_dir`
        do
                echo  "iterating files---->"$f

                temp4=$temp4"
"$f
#echo "------2"
                #echo $n
                if [ "$n" -ge "6" ] ; then
                                #echo "in if"
                                #echo $n
                                echo "---------------------Deleting File--------------------"
                                echo  "     "$f"             "
                                echo "------------------------------------------------------"
                                rm -rf $f
                                n=$(($n+1))
                                temp3=$temp3"
"$f
                        else
                                #echo "out of if"
                                #echo  $f
                                #echo "value of n is :---"$n
                                n=$(($n+1))

                fi
        done


#####WEEKLY BACKUP########

weekly=$(date +'%a')

if [ "$weekly" == "Sun" ] ; then

cp -r $backup_dir /home/centos/appdata/DB-Backup/Weekly/;

#DELETE weekly BACKUP

dir_week="/home/centos/appdata/DB-Backup/Weekly/"

echo "before dir_week"
cd $dir_week;
temp31="Deleting weekly Backups
"
temp41="Remaining weekly Backups
"
echo $dir_week;
        n=1;
        #echo "-------1"
        #ls

#        for f in `ls -t *.sql`
        for f in `ls -t $dir_week`
        do
                echo  "iterating files---->"$f

                temp41=$temp41"
"$f
#echo "------2"
                #echo $n
                if [ "$n" -ge "6" ] ; then
                                #echo "in if"
                                #echo $n
                                echo "---------------------Deleting File--------------------"
                                echo  "     "$f"             "
                                echo "------------------------------------------------------"
                                rm -rf $f
                                n=$(($n+1))
                                temp31=$temp31"
"$f
                        else

   #echo "out of if"
                                #echo  $f
                                #echo "value of n is :---"$n
                                n=$(($n+1))

                fi
        done
fi;



## DB SERVER STATUS
echo "Master DB-1 Server Disk Status :" > /usr/etc/NOKIA-Latin-DailyStatus.log
echo " " >> /usr/etc/NOKIA-Latin-DailyStatus.log
space=$(ssh -i "/etc/shc/shc-3.8.9/dmb/NOKIA-Latin.pem" centos@ec2-18-231-183-17.sa-east-1.compute.amazonaws.com "  df -h"$'\n'$'\n' $'\n'"echo 'MEMORY STATUS :'"$'\n'$'\n' " free -h  ");
echo "$space" >> /usr/etc/NOKIA-Latin-DailyStatus.log
echo " " >> /usr/etc/NOKIA-Latin-DailyStatus.log
echo "Master DB-2 Server Disk Status : " >> /usr/etc/NOKIA-Latin-DailyStatus.log
echo " " >> /usr/etc/NOKIA-Latin-DailyStatus.log
space=$(ssh -i "/etc/shc/shc-3.8.9/dmb/NOKIA-Latin.pem" centos@ec2-54-233-102-102.sa-east-1.compute.amazonaws.com "  df -h"$'\n'$'\n' $'\n'"echo 'MEMORY STATUS :'"$'\n'$'\n' " free -h  ");
echo "$space" >> /usr/etc/NOKIA-Latin-DailyStatus.log



#echo " RECENT BACKUP :-`date +%Y-%m-%d_%H:%M`"$'\n'"$temp2"$'\n'"$temp4" $'\n' $'\n'"$temp3"

echo " RECENT BACKUP  :  `date +%d-%B-%Y` "$'\n'$'\n'"$temp2"$'\n'"$temp4" $'\n' $'\n'"$temp3" $'\n'$'\n' "[NOTE] Please Find below attachment for Server Status " $'\n'$'\n' "Regards" $'\n' 'Sarthak Tomar' | mailx -v -c "rohit.saraf@innoeye.com, vipul.choure@innoeye.com, prateek.chauhan@innoeye.com  " -s "NOKIA-Latin Database BACKUP"   -a /usr/etc/NOKIA-Latin-DailyStatus.log " sarthak.tomar@innoeye.com , piyush.diwakar@innoeye.com "

#openssl enc -aes-256-cbc -d -in file.txt.enc -out file.txt    
