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

############nodejs#####################
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "system user created"
mkdir /app
VALIDATE $? "app directory created"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "copy data to temp"
cd /app 
VALIDATE $? "changed directory to app"
unzip /tmp/catalogue.zip
VALIDATE $? "unzipped from temp directory to app"
cd /app 
VALIDATE $? "changed directory to app"
npm install
VALIDATE $? "installed dependencies" 

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copied to enable systemuer"

systemctl daemon-reload
VALIDATE $? "reloaded catalogue" 
systemctl enable catalogue 
VALIDATE $? "enabled catalogue" 

systemctl start catalogue
VALIDATE $? "started catalogue" 

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding mongodb client" 

dnf install mongodb-mongosh -y
VALIDATE $? "installed mongodb" 

mongosh --host $MONGODB_HOST </app/db/master-data.js
VALIDATE $? "Load catalogue products"

systemctl restart catalogue
VALIDATE $? "restarted catalogue"




