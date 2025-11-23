#!/bin/bash

set -euo pipefail
trap 'echo "There is an error at $LINE_NO,command: $BASH_COMMAND"' ERR
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
echo "$0"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #$0 refers to the file which is running currently in
#the server which is mongodb.sh removes .sh and adds .log
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  #/var/log/shell-roboshop/mongodb.log
MONGODB_HOST="mongodb.dillshad.space"
SCRIPT_DIR=$PWD
mkdir -p $LOGS_FOLDER
echo "$LOG_FILE"
echo "script execution start time: $(date)" | tee -a $LOG_FILE    #appends the output to the logfile

USERID=$(id -u)    

#returns pwd user id which should be 0 if it is sudo user and that 0 value is stoed in userid

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run in sudo user $N" | tee -a $LOG_FILE
    exit 1
    #failure code is other than "0"
fi



############nodejs#####################
dnf module disable nodejs -y &>>$LOG_FILE

dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE

echo "installed nodejs"

id roboshop &>>$LOG_FILE 
if [ $? -ne 0 ]; then

   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else
   echo -e "user already exisiting .. $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE 


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE


rm -rf /app/* &>>$LOG_FILE 


cd /app  &>>$LOG_FILE


unzip /tmp/catalogue.zip &>>$LOG_FILE


cd /app  &>>$LOG_FILE


npm install &>>$LOG_FILE


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service


systemctl daemon-reload &>>$LOG_FILE
 

systemctl enable catalogue  &>>$LOG_FILE


systemctl UNABLE catalogue &>>$LOG_FILE


cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
 

dnf install mongodb-mongosh -y &>>$LOG_FILE


INDEX=$(mongosh mongodb.dillshad.space --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
   mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
   echo -e "dbs are present .. $Y SKIPPING $N"
fi

systemctl restart catalogue &>>$LOG_FILE
