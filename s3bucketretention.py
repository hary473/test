import boto3

bucket_name = 'med-av-daas-preprod-datasci'

#Create an S3 client
s3 = boto3.client('s3')

#Create the lifecycle configuration
lifecycle_config = {
   'Rules': [
       {
           'Expiration': {
               'Days': 30
           },
           'Filter': {
               'Prefix': 'logs/'
           },
           'ID': 'delete-logs-after-30-days',
           'Status': 'Enabled',
           'Transitions': [
               {
                   'Days': 14,
                   'StorageClass': 'GLACIER'
               }
           ]
       }
   ]
}

#Set the lifecycle configuration for the bucket
s3.put_bucket_lifecycle_configuration(
   Bucket=bucket_name,
   LifecycleConfiguration=lifecycle_config
)

print(f'Retention policy added to S3 bucket: {bucket_name}')