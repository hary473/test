cd /emr
#Set threshold for disk usage
threshold=70
#Get current disk usage percentage for /emr directory
disk_usage=$(df -h | awk '$NF=="/emr"{print int($5)}')
#If disk usage exceeds threshold, copy logs to S3, delete from /emr, and send SNS notification
if [ $disk_usage -gt $threshold ]
then
#Set S3 bucket name
s3_bucket=s3://med-av-daas-preprod-datasci/user/lh335896/
#Set SNS topic ARN and email address to receive notifications
sns_topic_arn=arn:aws:sns:us-east-1:958262988361:datasci-cluster6-v23-emr-cicd-pipeline-stage-stack-email-notification
#Copy logs to S3
aws s3 sync /emr/apppusher/log/ s3://s3://med-av-daas-preprod-datasci/user/lh048689//logs/apppusher/
aws s3 sync /emr/instance-state/ s3://s3://med-av-daas-preprod-datasci/user/lh048689//logs/instance-state/
aws s3 sync /emr/logpusher/log/ s3://s3://med-av-daas-preprod-datasci/user/lh048689//logs/logpusher/
aws s3 sync /emr/service-nanny/log/ s3://s3://med-av-daas-preprod-datasci/user/lh048689//logs/service-nanny/
#Verify all logs are copied to S3 before deleting them from /emr
if aws s3 ls "s3://$s3_bucket/logs/apppusher/" && \
aws s3 ls "s3://$s3_bucket/logs/instance-state/" && \
aws s3 ls "s3://$s3_bucket/logs/logpusher/" && \
aws s3 ls "s3://$s3_bucket/logs/service-nanny/"; then
#Delete logs from /emr
sudo rm /emr/apppusher/log/*.gz
sudo rm /emr/instance-state/*.gz
sudo rm /emr/logpusher/log/*.gz
sudo rm /emr/service-nanny/log/*.gz
#Send SNS notification
message="EMR disk usage exceeded threshold of $threshold%. Logs have been copied to S3 and deleted from /emr directory."
aws sns publish --topic-arn arn:aws:sns:us-east-1:958262988361:datasci-cluster6-v23-emr-cicd-pipeline-stage-stack-email-notification --message "$message" --subject "EMR Disk Usage Alert"
else
echo "ERROR: Failed to copy all logs to S3. Exiting without deleting logs from /emr."
exit 1
fi
fi
#Add crontab entry to run this script every 5 minutes
echo "setting cron"
echo "*/5 * * * * /bin/bash /root/emrlogs.sh" | sudo crontab -