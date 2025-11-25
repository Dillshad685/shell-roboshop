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
MYSQL_HOST=mysql.dillshad.space
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

############ java #####################

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "install java"

id roboshop &>>$LOG_FILE 
if [ $? -ne 0 ]; then

   uuseradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
   VALIDATE $? "system user created"
else
   echo -e "user already exisiting .. $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE 
VALIDATE $? "app directory created"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "copy data to temp"

rm -rf /app/* &>>$LOG_FILE 
VALIDATE $? "removing existing CODE" 

cd /app  &>>$LOG_FILE
VALIDATE $? "changed directory to app"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipped from temp directory to app"

cd /app  &>>$LOG_FILE
VALIDATE $? "changed directory to app"

mvn clean package &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "installed packages" 


cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copied to enable systemuser"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloaded shipping" 

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "enabled shipping" 

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "started shipping" 

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installed mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' < /app/db/schema.sql &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo"Mysql data is loaded .. $Y SKIPPING $N"

fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "shipping restarted"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"