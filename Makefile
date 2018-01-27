# Change here or use environment variables, e.g. export AWS_PROFILE=<aws profile name>.

# Default SHELL for make for consistency on different platforms
SHELL := /bin/bash

#Taken from  /.aws/credentials
AWS_PROFILE             ?= karoljunde
AWS_ACCOUNT		        := $(shell aws --profile ${AWS_PROFILE} iam get-user | jq -r ".User.Arn" | grep -Eo '[[:digit:]]{12}')
AWS_ACCESS_KEY_ID       := $(shell aws --profile ${AWS_PROFILE} configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY   := $(shell aws --profile ${AWS_PROFILE} configure get aws_secret_access_key)
BACKUP_IMAGE            ?= dynamodb-backup
RESTORE_IMAGE           ?= dynamodb-restore
REGION                  ?= eu-west-1
S3_BUCKET               ?= aws-karol-storage
SRC_DB_TABLE            ?= Products
RCU 					?= 1000
WCU 					?= 2
RESTORED_DB_TABLE       ?= Restored
DATE_OF_BACKUP			?= 2018-01-25-11-09-09



.ONESHELL:
SHELL := /bin/bash
.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

backup: ## Build, Run Docker image for Dynamodb backup
	@tput sgr0; echo -n "Build and run image $(BACKUP_IMAGE) in account  - " ; tput sgr0; tput setaf 1; tput bold; echo "$(AWS_ACCOUNT) "
	@docker build -f Dockerfile_backup -t $(BACKUP_IMAGE) .
	@docker run -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	--env-file=env_file_backup \
	-d $(BACKUP_IMAGE)

update-rcu-wcu: ## Change appropriate value of RCU and WCU for source table; default RCU=1000,WCU=2
	@tput sgr0; echo -n "Changing RCU in $(SRC_DB_TABLE) into value $(RCU) in account  - " ; tput sgr0; tput setaf 1; tput bold; echo "$(AWS_ACCOUNT) "
	@aws dynamodb update-table --table-name $(SRC_DB_TABLE) --provisioned-throughput ReadCapacityUnits=$(RCU),WriteCapacityUnits=$(WCU) --region $(REGION)


restore: ## Build, Run Docker image for Dynamodb restoration
	@tput sgr0; echo -n "Build and run image $(RESTORE_IMAGE) in account  - " ; tput sgr0; tput setaf 1; tput bold; echo "$(AWS_ACCOUNT) "
	@docker build -f Dockerfile_restore -t $(RESTORE_IMAGE) .
	@docker run -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	--env-file=env_file_restore \
	-d $(RESTORE_IMAGE)


list-items-source: ## List items in source Dynamodb table
	@tput sgr0; echo -n "Count items in Dynamodb table $(SRC_DB_TABLE) in account  - " ; tput sgr0; tput setaf 1; tput bold; echo "$(AWS_ACCOUNT) "
	@aws dynamodb scan --table-name $(SRC_DB_TABLE) --select COUNT --region $(REGION)


list-items-restored: ## List items in restored Dynamodb table
	@tput sgr0; echo -n "Count items in Dynamodb table $(RESTORED_DB_TABLE) in account  - " ; tput sgr0; tput setaf 1; tput bold; echo "$(AWS_ACCOUNT) "
	@aws dynamodb scan --table-name $(RESTORED_DB_TABLE) --select COUNT --region $(REGION)


list-bucket: ## List destination S3 bucket for backups and all of its contents
	@tput sgr0; echo -n "Listing S3 bucket - " ; tput sgr0; tput setaf 1; tput bold; echo "$(S3_BUCKET) "
	@aws s3 ls s3://$(S3_BUCKET)/

list-bucket-path: ## List destination S3 bucket directory according to date; DATE_OF_BACKUP=2018-01-25-11-09-09
	@tput sgr0; echo -n "Listing S3 bucket path DynamoDB-backup-$(DATE_OF_BACKUP)/ in - " ; tput sgr0; tput setaf 1; tput bold; echo "$(S3_BUCKET) "
	@aws s3 ls s3://$(S3_BUCKET)/DynamoDB-backup-$(DATE_OF_BACKUP)/

