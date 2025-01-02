#!/usr/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_instance_template () {
    if ! gcloud compute instance-templates list --quiet 2>&1 | grep -w "$TEMPLATE_NAME" 2>&1; then
        return 0
    else
        return 1
    fi
}

create_instance_template () {
    TOPIC="Create Instance Template"
    ERROR=-1
    OUTPUT="Creating instance template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_instance_template; then
        EXTRA=$(gcloud compute instance-templates create $BASIC_TEMPLATE_NAME \
        --project=$PROJECT_NAME \
        --network=$NETWORK_NAME \
        --scopes "https://www.googleapis.com/auth/cloud-platform" \
        --machine-type=$MACHINE_TYPE \
        --service-account=$SERVICE_ACCOUNT \
        --create-disk=auto-delete=yes,boot=yes,device-name=physical-instance-test,image=$IMAGE,mode=rw,size=10,type=pd-balanced \
        --metadata-from-file startup-script=./startup-script.sh \
        --labels=ops-agent=yes \
        --tags dotnet-instance,http-server,https-server 2>&1)

        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating instance template"
            ERROR=1
            write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
        else
            OUTPUT="Instance template created"
            ERROR=0
            write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
        fi

    else
        OUTPUT="Instance template already exists"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR
        
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_instance_template () {
    TOPIC="delete instance template"
    ERROR=-1
    OUTPUT="Deleting instance template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_instance_template; then
        EXTRA=$(gcloud compute instance-templates delete $BASIC_TEMPLATE_NAME --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting instance template"
            ERROR=1
            write_log_to_file $TOPIC $OUTPUT $ERROR
        else
            OUTPUT="Instance template deleted"
            ERROR=0
            write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
        fi
    else
        OUTPUT="Instance template does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}