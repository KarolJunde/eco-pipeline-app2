# DynamoDB Backup & Restore

>Short-term solution until AWS DynamoDB Backup & Restore is available in eu-central-1.

- backup DynamoDB tables
- restore DynamoDB tables from backup
- Makefile


>You can run code inside built on local machine with Docker environment or as a container inside ECS/K8s cluster
Code has been downloaded from https://github.com/markitx/dynamo-backup-to-s3

### Important note regarding BACKUP process
> Keep in mind that backup process may require increased number of RCUs for particular table(s) which can be set via Makefile(see: 'make update-rcu-wcu')

### Available arguments for RESTORATION SCRIPT
```
  Available arguments in Dockerfile for restoration script ./bin/dynamo-restore-from-s3:

    -h, --help                        output usage information
    -V, --version                     output the version number
    -s, --source [path]               Full S3 path to a JSON backup file (Required)
    -t, --table [name]                Name of the Dynamo Table to restore to (Required)
    -o, --overwrite                   Table already exists, skip auto-create. Default is false.
    -c, --concurrency <requestcount>  Number of concurrent requests & dynamo capacity units.Defaults to 200.
    -pk, --partitionkey       Name of Primary Partition Key. If not provided will try determine from backup.
    -sk, --sortkey [columnname]       Name of Secondary Sort Key. Ignored unless --partitionkey is provided.
    -rc, --readcapacity <units>       Read Units for new table (when finished). Default is 5.
    -wc, --writecapacity <units>      Write Units for new table (when finished). Default is --concurrency.
    -sf, --stop-on-failure            Stop process when the same batch fails to restore multiple times. Default to false.
    --aws-key <key>                   Will use AWS_ACCESS_KEY_ID env var if --aws-key not set
    --aws-secret <secret>             Will use AWS_SECRET_ACCESS_KEY env var if --aws-secret not set
    --aws-region <region>             Will use AWS_DEFAULT_REGION env var if --aws-region not set
```
### Example:
```
./bin/dynamo-restore-from-s3 -t <new_table_name> -c <concurrency> -s <source_json_file> --readcapacity <rcu> --writecapacity <wcu> --aws-region <region>
```
> NOTE: Default flag: -sf, --stop-on-failure is set on FALSE. If you want to stop process when the same batch fails to restore multiple times change in Dockerfile-restore:
```
./bin/dynamo-restore-from-s3 -t <new_table_name> -c <concurrency> -s <source_json_file> --readcapacity <rcu> --writecapacity <wcu> --aws-region <region> --stop-on-failure 
```

### Available arguments for BACKUP SCRIPT
```
 Usage: dynamo-backup-to-s3 [options]

  Options:

    -h, --help                       output usage information
    -V, --version                    output the version number
    -b, --bucket <name>              S3 bucket to store backups
    -s, --stop-on-failure            specify the reporter to use
    -r, --read-percentage <decimal>  specific the percentage of Dynamo read capacity to use while backing up. default .25 (25%)
    -x, --excluded-tables <list>     exclude these tables from backup
    -i, --included-tables <list>     only backup these tables
    -p, --backup-path <name>         backup path to store table dumps in. default is DynamoDB-backup-YYYY-MM-DD-HH-mm-ss
    -e, --base64-encode-binary       if passed, encode binary fields in base64 before exporting
    -d, --save-datapipeline-format   save in format compatible with the AWS datapipeline import. Default to false (save as exported by DynamoDb)
    --aws-key                        AWS access key. Will use AWS_ACCESS_KEY_ID env var if --aws-key not set
    --aws-secret                     AWS secret key. Will use AWS_SECRET_ACCESS_KEY env var if --aws-secret not set
    --aws-region                     AWS region. Will use AWS_DEFAULT_REGION env var if --aws-region not set
```
### Example backup flags in Dockerfile-backup with selected table:
```
./bin/dynamo-backup-to-s3 -b <name> -i <name> --aws-region <region>
```
### Example backup flags in Dockerfile-backup with excluded table:
```
./bin/dynamo-backup-to-s3 -b <name> -x <name> --aws-region <region>
```
> NOTE: Default flag: -sf, --stop-on-failure is set on FALSE. If you want to stop process when the errors occur use:
```
./bin/dynamo-backup-to-s3 -b <name> -i <name> --aws-region <region> --stop-on-failure 
```

### Basic Commands

### Installation for local Docker deamon
```sh
$ export AWS_PROFILE=value
$ echo $AWS_PROFILE
$ git clone https://gitlab.com/nexiot-ag/sre/maintenance/dynamodb-backup.git
$ cd dynamodb-backup
```
### Check and edit environmental variables for BACKUP PROCESS in env_file_backup used during docker run process
```
$ vi env_file_backup

TABLE_NAME=Products
S3_BUCKET=nexiot-sandbox-backup
REGION=eu-central-1

```
### Check and edit environmental variables for RESTORATION PROCESS in env_file_restore used during docker run process
```
$ vi env_file_restore

TABLE_NAME=Restored
RCU=5
WCU=5
CONCURRENCY_LEVEL=1000
REGION=eu-central-1
S3_JSON_FILE=s3://nexiot-sandbox-backup/DynamoDB-backup-2017-12-15-19-18-12/Products.json
```
### List available options in Makefile
```
$ make
backup                         Build, Run Docker image for Dynamodb backup
list-bucket-path               List destination S3 bucket directory according to date; DATE_OF_BACKUP=2018-01-25-11-09-09
list-bucket                    List destination S3 bucket for backups and all of its contents
list-items-restored            List items in restored Dynamodb table
list-items-source              List items in source Dynamodb table
restore                        Build, Run Docker image for Dynamodb restoration
update-rcu-wcu                 Change appropriate value of RCU and WCU for source table; default RCU=1000,WCU=2
```
### Before launching BACKUP process you can change RCU for particular table - MAKE UPDATE-RCU-WCU
```
$ make update-rcu-wcu RCU=x SRC_DB_TABLE=<table_name>
```

### BACKUP TABLE
### Run script for docker build and run
```
$ make backup
...
Successfully built 8442fce0b126
Successfully tagged dynamodb-backup:latest

$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
dynamodb-backup     latest              8442fce0b126        8 minutes ago       194MB
```
### Check whether the process succeded (Exited with code 0)
```
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                     PORTS               NAMES
c3c3c666e64d        dynamodb-backup     "/bin/sh -c './bin/d…"   6 minutes ago       Exited (0) 8 seconds ago                       sad_nightingale
```
### 'make list-bucket <args>' or 'make list-bucket-path <args> to check backuped json file in S3
```
$ make list-bucket S3_BUCKET=<bucket_name>
Listing S3 bucket - nexiot-sandbox-backup
                           PRE DynamoDB-backup-2018-01-09-10-31-56/
                           PRE DynamoDB-backup-2018-01-24-16-12-49/
                           PRE DynamoDB-backup-2018-01-25-11-09-09/
```
then select which backup folder:
```
$ make list-bucket-path DATE_OF_BACKUP=<date> S3_BUCKET=<bucket_name>
Listing S3 bucket path DynamoDB-backup-2018-01-25-11-09-09/ in - nexiot-sandbox-backup
2018-01-25 12:22:29     975324 <table_name>.json
```
> NOTE: DATE format example : 2018-01-25-11-09-09

### RESTORE TABLE
### Run script for docker build and run
```
$ make restore
...
Successfully built 74c262dfdf08
Successfully tagged dynamodb-restore:latest

$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
dynamodb-restore    latest              74c262dfdf08       40 seconds ago      156MB
```
### Count number of items in source/destination table
```
$ make list-items-source
or
$ make list-items-restored
```
### Check whether the process succeded (Exited with code 0)
```
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                 CREATED             STATUS         PORTS               NAMES
74c262dfdf08        dynamodb-restore    "/bin/sh -c 'cd /opt…"   About a minute ago   Exited (0) About a minute ago quirky_maye

$ docker logs 74c262dfdf08
Starting download. xxx remaining...
...
Done! Process completed in N minutes M seconds.
```

### To inspect container - example
```
$ docker inspect 74c262dfdf08
```

### To delete container - example
```
$ docker rm 74c262dfdf08
```

### To delete image dynamodb-restore/dynamodb-backup - example
```
$ docker rmi dynamodb-restore
$ docker rmi dynamodb-backup
```


