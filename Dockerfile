FROM node:9.3-alpine

ADD package*.json /tmp/
RUN cd /tmp && npm install
RUN mkdir -p /opt/dynamodb-backup-restore && cp -a /tmp/node_modules /opt/dynamodb-backup-restore/

WORKDIR /opt/dynamodb-backup-restore
ADD . /opt/dynamodb-backup-restore

ENV TABLE_NAME ProductRestore
ENV RCU 5
ENV WCU 5
ENV S3_JSON_FILE s3://aws-karol-storage/DynamoDB-backup-2018-01-09-10-31-56/Products.json
ENV CONCURRENCY_LEVEL 400
ENV REGION eu-west-1
RUN ["chmod", "+x", "/opt/dynamodb-backup-restore/bin/dynamo-restore-from-s3"]
CMD cd /opt/dynamodb-backup-restore && ./bin/dynamo-restore-from-s3 -t $TABLE_NAME -c $CONCURRENCY_LEVEL -s $S3_JSON_FILE --readcapacity $RCU --writecapacity $WCU --aws-region $REGION