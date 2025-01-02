#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_bucket () {
    # Check if the bucket exists
    if ! gsutil ls | grep $BUCKET_NAME > /dev/null; then
        return 0
    else
        return 1
    fi
}

create_cloud_bucket () {

    TOPIC="Create cloud bucket"
    ERROR=-1
    OUTPUT="Creating bucket $BUCKET_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Create the bucket

    if check_bucket; then
        EXTRA=$(gcloud storage buckets create gs://$BUCKET_NAME  --project $PROJECT_NAME --location=eu 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating bucket $BUCKET_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA

        else
            OUTPUT="Bucket $BUCKET_NAME created"
            ERROR=0

            write_to_screen $TOPIC $ERROR $OUTPUT

            # Add service account as object admin and all users as object viewer

            EXTRA=$(gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/storage.admin 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error adding service account $SERVICE_ACCOUNT as object admin"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
             else
                OUTPUT="Service account $SERVICE_ACCOUNT added as object admin"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            fi
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA

            EXTRA=$(gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error adding allUsers as object viewer"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            else
                OUTPUT="All users added as object viewer"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            fi
            write_to_screen $TOPIC $ERROR $OUTPUT
        fi 
        
    else
        echo $ERROR_BUCKET
        OUTPUT="Bucket $BUCKET_NAME already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Write the bucket name to a temp file

    if ! cat $TEMP_FILE | grep -w $BUCKET_NAME > /dev/null; then
        TO_WRITE="BUCKET_NAME=\"$BUCKET_NAME\"" 
        echo "$TO_WRITE"  2>&1 | cat >> $TEMP_FILE 2>&1
        OUTPUT="Writing bucket name to temp file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else 
        OUTPUT="Bucket name already exists in temp file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}



delete_cloud_bucket () {
    TOPIC="Delete cloud bucket"
    ERROR=-1
    OUTPUT="Deleting bucket $BUCKET_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Delete the bucket

    if ! check_bucket &> /dev/null; then
        EXTRA=$(gsutil rm -r gs://$BUCKET_NAME 2>&1)

        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting bucket $BUCKET_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Bucket $BUCKET_NAME deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    
    else
        OUTPUT="Bucket $BUCKET_NAME does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

get_bucket_name () {
    TOPIC="Get bucket name"
    ERROR=-1
    OUTPUT="Requesting bucket name that is related to $PROJECT_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Get the bucket name that is related to the project name

    EXTRA=$(gsutil ls | grep $PROJECT_NAME | awk -F/ '{print $3}' 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error getting bucket name"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        BUCKET_NAME=$EXTRA
        OUTPUT="Bucket name $BUCKET_NAME found"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    write_to_screen $TOPIC $ERROR $OUTPUT
}
