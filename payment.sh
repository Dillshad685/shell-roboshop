#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
echo "$0"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #$0 refers to the file which is running currently in
#the server which is mongodb.sh removes .sh and adds .log
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"  #/var/log/shell-roboshop/mongodb.log
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "installed python"

id roboshop &>>$LOG_FILE 
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "SYSTEMUSER created"
else
    echo -e "system user already created .. $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "app directory created"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "payment file created"

cd /app &>>$LOG_FILE
VALIDATE $? "moved to app directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "remove code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "MOVED TO TEMP"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installed packages"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "systemctl service enabled"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "PAYMENT reloaded"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "ENABLED payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "Started payment"

