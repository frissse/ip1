#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh


check_secrets () {
    if ! gcloud secrets list --quiet | grep -w $SECRETS_NAME > /dev/null; then
        return 0
    else
        return 1
    fi
}

create_secrets () {
    TOPIC="Create secrets"
    ERROR=-1
    OUTPUT="Creating secrets $SECRETS_NAME"
    
    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_secrets; then
        EXTRA=$(gcloud secrets create $SECRETS_NAME --replication-policy="automatic" --data-file=$TEMP_FILE 2>&1)
        OUTPUT="Secrets $SECRETS_NAME created"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA

        OUTPUT="Adding IAM policy binding to secrets $SECRETS_NAME"
        write_to_screen $TOPIC $ERROR $OUTPUT
        
        EXTRA=$(gcloud secrets add-iam-policy-binding phygital-secrets \
            --member=serviceAccount:$SERVICE_ACCOUNT \
            --role="roles/secretmanager.admin" 2>&1)

        if [ $? -eq 0 ]; then
            ERROR=0
            OUTPUT="Service account $SERVICE_ACCOUNT added as secret manager admin"
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            write_to_screen $TOPIC $ERROR $OUTPUT
        else 
            ERROR=1
            OUTPUT="Service account $SERVICE_ACCOUNT not added as secret manager admin"
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            write_to_screen $TOPIC $ERROR $OUTPUT
        fi

    else
        OUTPUT="Secrets $SECRETS_NAME already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_secrets () {
    TOPIC="Delete secrets"
    ERROR=-1
    OUTPUT="Deleting secrets $SECRETS_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_secrets; then
        EXTRA=$(gcloud secrets delete $SECRETS_NAME  --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting secrets $SECRETS_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Secrets $SECRETS_NAME deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Secrets $SECRETS_NAME does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}