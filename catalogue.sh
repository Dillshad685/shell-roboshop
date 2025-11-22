#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
echo "$0"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #$0 refers to the file which is running currently in
#the server which is mongodb.sh removes .sh and adds .log
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  #/var/log/shell-roboshop/mongodb.log
MONGODB_HOST=mongodb.dillshad.space
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

VALIDATE(){ #function receives input as args
  if [ $1 -ne 0 ]; then  
     echo -e " Installation failed .. $R FAILURE $N" | tee -a $LOG_FILE
     exit 1
  else
     echo -e "$2 .. $G SUCCESS $N" | tee -a $LOG_FILE
  fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "Adding mongorepo"
############nodejs#####################
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "system user created"
mkdir /app
validate $? "app directory created"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "copy data to temp"
cd /app 
validate $? "changed directory to app"
unzip /tmp/catalogue.zip
validate $? "unzipped from temp directory to app"
cd /app 
validate $? "changed directory to app"
npm install
validate $? "installed dependencies" 

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "copied to enable systemuer"

systemctl daemon-reload
validate $? "reloaded catalogue" 
systemctl enable catalogue 
validate $? "enabled catalogue" 

systemctl start catalogue
validate $? "started catalogue" 

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
validate $? "adding mongodb client" 

dnf install mongodb-mongosh -y
validate $? "installed mongodb" 

mongosh --host $MONGODB_HOST </app/db/master-data.js
validate $? "Load catalogue products"

systemctl restart catalogue
validate $? "restarted catalogue"




