#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


LOGS_FOLDER="/var/log/shell-roboshop"
echo "$0"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #$0 refers to the file which is running currently in
#the server which is mongodb.sh removes .sh and adds .log
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  #/var/log/shell-roboshop/
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


cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "repo file created"
###### rabbitmq ########
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "install rabbitmq"
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enable rabbitmq-server"
systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "start rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "root pwd set"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "permissions given"



END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"