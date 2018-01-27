FROM node:9.3-alpine

ADD package*.json /tmp/
RUN cd /tmp && npm install
RUN mkdir -p /opt/dynamodb-backup-restore && cp -a /tmp/node_modules /opt/dynamodb-backup-restore/

WORKDIR /opt/dynamodb-backup-restore
ADD . /opt/dynamodb-backup-restore
RUN ["chmod", "+x", "/opt/dynamodb-backup-restore/bin/dynamo-backup-to-s3"]

ENV TABLE_NAME Products
ENV S3_BUCKET nexiot-sandbox-backup
ENV REGION eu-central-1
CMD ./bin/dynamo-backup-to-s3 -b $S3_BUCKET -i $TABLE_NAME --aws-region $REGION