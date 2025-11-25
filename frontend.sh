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
SCRIPT_DIR=$PWD
mkdir -p $LOGS_FOLDER
echo "$LOG_FILE"
echo "script execution start time: $(date)" | tee -a $LOG_FILE    #appends the output to the logfile
START_TIME=$(date +%s)

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

dnf module disable nginx -y &>>LOG_FILE 
VALIDATE $? "disabled nginx"

dnf module enable nginx:1.24 -y &>>LOG_FILE
VALIDATE $? "enabled nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installed nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enabled nginx"
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "started nginx" 

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "existing code removed"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "code copied to tmp"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "changed to main folder"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "code copied"

rm -rf /etc/nginx/nginx.conf 
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "code copied to nginx config"

systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "started nginx" 
