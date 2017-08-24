#!/bin/bash

renice 19 -p $$ 

backup_parent_dir="/Server-Backup"
cpanel_backup_log="/tmp/cpanel_backup.log"


emailalert="mailid@domain.com mailid@domain.com mailid@domain.com"

ret_time=1

#Here list the exclude list of from backup
exlist=("some_large" "too_large" "supportacc")

tmpfile=`mktemp` ;
echo "Temp file path is $tmpfile" ;
ls /var/cpanel/users > $tmpfile ;

matched="0"
# Start account backup
for CTID in $( cat $tmpfile)
do
	echo "Taking backup of the account $CTID" ;
	for e in "${exlist[@]}"
	do
		if [[ "$e" == "$CTID" ]]
		then
			matched="1"
			break ; # Dont take backup
		fi
	done

	if [ $matched = "1" ]  #Pattern match
    then
		echo "Not Backing up for account $CTID"
		matched="0"
		continue 
	fi

	### Check if a directory does not exist ###
	if [ ! -d "/home/$CTID" ] 
	then
    	echo "Directory /home/$CTID DOES NOT exists." 
		continue 
	fi

	echo "finding *$CTID*.tar.gz" ;
	find $backup_parent_dir  -maxdepth 1 -mtime -7 -type f -name "*$CTID*.tar.gz"  | grep $CTID
	if [ $? -eq 0 ]
	then
		echo "Recently backup taken, So not taking now." 
		continue ;
	fi
	echo "finding done" ;
	
	tempTime=`date +%k%M`
    if [ $tempTime -gt 500 -a $tempTime -lt 2100 ]; then
        ret_time=1
    else
        ret_time=0
    fi
	
	while [ $ret_time -gt 0 ]
	do
		tempTime=`date +%k%M`
		if [ $tempTime -gt 500 -a $tempTime -lt 2100 ]; then
   	    	ret_time=1
	    else
    	    ret_time=0
	    fi
	    echo "Daytime $tempTime sleeping Sleeping $ret_time , need to continue backup user $CTID" ;
	    sleep 100
	done

	echo "Taking backup of the account $CTID Started" ;
    /scripts/pkgacct $CTID $backup_parent_dir --backup $backup_parent_dir > $cpanel_backup_log
    echo "Taking backup of the account $CTID Done" ;

	echo "Sleeping 10 seconds....."
	sleep 10
	
	ftpserver='IP Address';
	ftpuser='ftp-username'
	ftppass="ftp-password"
	dt=`date +"%b-%d-%y"`
	
	echo "Ftping the account" ;
	###change directory to backup directory
ftp -dvin $ftpserver << SCRIPTEND
	user $ftpuser $ftppass
	binary
	cd weekly/
	put $backup_parent_dir/$CTID.tar.gz $CTID-$dt.tar.gz
SCRIPTEND

	echo "Sleeping 20 seconds....."
	sleep 20
done
 
echo "Backup tasks completed on `date` - showing directory listing"
