#!/bin/bash

source config.sh

CREATE_SECRETS="gcloud secrets create $SECRETS_NAME --replication-policy="automatic" --data-file=env-var.txt"
