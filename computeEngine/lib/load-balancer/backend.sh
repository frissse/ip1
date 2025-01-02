#!/usr/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_lb_backend () {
    if ! gcloud compute backend-services list --global | grep $LB_BACKEND &> /dev/null; then
        return 0
    else
        return 1
    fi
}

create_lb_backend () {
    TOPIC="Create load balancer backend"
    ERROR=-1
    OUTPUT="Creating load balancer backend $LB_BACKEND"
    write_to_screen $TOPIC $ERROR $OUTPUT


    if check_lb_backend &> /dev/null; then
        EXTRA=$(gcloud compute backend-services create $LB_BACKEND \
            --load-balancing-scheme=EXTERNAL \
            --protocol=HTTP \
            --port-name=http \
            --health-checks $HEALTH_CHECK \
            --timeout 1800 \
            --global 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating Load balancer backend $LB_BACKEND"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Load balancer backend $LB_BACKEND created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi

        write_to_screen $TOPIC $ERROR $OUTPUT

    else
        OUTPUT="Load balancer backend $LB_BACKEND already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi


    EXTRA=$(gcloud compute backend-services add-backend $LB_BACKEND \
        --instance-group=$INSTANCE_GROUP \
        --instance-group-region=$REGION \
        --global 2>&1)
    
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error adding instance group $INSTANCE_GROUP to load balancer backend $LB_BACKEND"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Instance group $INSTANCE_GROUP added to load balancer backend $LB_BACKEND"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

remove_lb_backend () {
    TOPIC="Removing load balancer backend"
    ERROR=-1
    OUTPUT="Deleting load balancer backend $LB_BACKEND"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_lb_backend &> /dev/null; then
        EXTRA=$(gcloud compute backend-services remove-backend $LB_BACKEND --instance-group-region $REGION --instance-group=$INSTANCE_GROUP --global 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleteing Load balancer backend $LB_BACKEND"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Load balancer backend $LB_BACKEND removed from instance group"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi

    else
        OUTPUT="Load balancer backend $LB_BACKEND does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
        write_to_screen $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_lb_backend () {
    TOPIC="Delete load balancer backend"
    ERROR=-1
    OUTPUT="Deleting load balancer backend $LB_BACKEND"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_lb_backend &> /dev/null; then
        EXTRA=$(gcloud compute backend-services delete $LB_BACKEND --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting Load balancer backend $LB_BACKEND"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Load balancer backend $LB_BACKEND deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Load balancer backend $LB_BACKEND does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}