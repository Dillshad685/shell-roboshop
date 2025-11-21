#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"  #we get from existing instance
SG_ID="sg-00d0eb3bdf7ae9959" #same as above
Zone_ID="Z0375645LTAC4FZXZR6K"
Domain_name="dillshad.space"

for instance in $@ #$@ refers to the variables we pass dynamically
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)  #to create EC2 instance using shell here instance name which we give dynamically is stored in $instance

    #to get private IP
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$Domain_name"
    else 
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$Domain_name"
    fi

    echo "$instance: $IP"  #returns instancename=its IP address

     aws route53 change-resource-record-sets \
   --hosted-zone-id $Zone_ID \
   --change-batch '
    {
     "Comment": "Updating record set"
     ,"Changes": [{
       "Action"              : "UPSERT"
       ,"ResourceRecordSet"  : {
         "Name"              : "'$RECORD_NAME'"
         ,"Type"             : "A"
         ,"TTL"              : 1
         ,"ResourceRecords"  : [{
             "Value"         : "'$IP'"
         }]
       }
     }]
   }
    '
done