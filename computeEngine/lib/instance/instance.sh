#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_instance () {
    if ! gcloud compute instances describe $INSTANCE_NAME --zone $ZONE &> /dev/null; then
        return 0
    else
        return 1
    fi
}

create_instance () {
    TOPIC="Create Instance"
    OUTPUT="Creating instance $INSTANCE_NAME from template $BASIC_TEMPLATE_NAME in zone $ZONE"
    write_to_screen 

    if check_instance; then
        EXTRA=$(gcloud compute instances create $INSTANCE_NAME \
            --source-instance-template $BASIC_TEMPLATE_NAME \
            --zone $ZONE 2>&1)
        if [ $? -eq 0 ]; then
            ERROR=0
            OUTPUT="Instance $INSTANCE_NAME created"
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            ERROR=-1
            OUTPUT="Error creating instance $INSTANCE_NAME"
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        ERROR=-1
        OUTPUT="Instance $INSTANCE_NAME already exists"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

}

delete_instance () {
    TOPIC="Delete Instance"
    OUTPUT="Deleting instance $INSTANCE_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_instance; then
        EXTRA=$(gcloud compute instances delete $INSTANCE_NAME --zone $ZONE --quiet 2>&1)
        if [ $? -eq 0 ]; then
            ERROR=0
            OUTPUT="Instance $INSTANCE_NAME deleted"
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            ERROR=-1
            OUTPUT="Error deleting instance $INSTANCE_NAME"
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        ERROR=-1
        OUTPUT="Instance $INSTANCE_NAME does not exist"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}