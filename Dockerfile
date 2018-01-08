FROM node:9.3-alpine

ADD package*.json /tmp/
RUN cd /tmp && npm install
RUN mkdir -p /opt/dynamodb-backup-restore && cp -a /tmp/node_modules /opt/dynamodb-backup-restore/

WORKDIR /opt/dynamodb-backup-restore
ADD . /opt/dynamodb-backup-restore

CMD cd /opt/dynamodb-backup-restore && dynamo-backup-to-s3 -b aws-karol-storage -i Products --aws-region eu-west-1