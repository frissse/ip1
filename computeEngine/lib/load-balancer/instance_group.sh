#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_instance_group () {
    if ! gcloud compute instance-groups list --regions $REGION --quiet | grep -w $INSTANCE_GROUP > /dev/null; then
        return 0
    else
        return 1
    fi
}

create_instance_group () {
    TOPIC="Create instance group"
    ERROR=-1
    OUTPUT="Creating instance group $INSTANCE_GROUP"

    write_to_screen $TOPIC $ERROR $OUTPUT

    #creates an instance group with the given instance template and instance group size set in the config file

    if check_instance_group ; then
        EXTRA=$(gcloud compute instance-groups managed create $INSTANCE_GROUP --region $REGION --template $BASIC_TEMPLATE_NAME --size $INSTANCE_GROUP_SIZE 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating instance group $INSTANCE_GROUP"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Instance group $INSTANCE_GROUP created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        OUTPUT="Instance group $INSTANCE_GROUP already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_instance_group () {
    TOPIC="Delete instance group"
    ERROR=-1
    OUTPUT="Deleting instance group $INSTANCE_GROUP"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_instance_group; then
        EXTRA=$(gcloud compute instance-groups managed delete $INSTANCE_GROUP --region $REGION --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting instance group $INSTANCE_GROUP"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Instance group $INSTANCE_GROUP deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA 
        fi
    else 
        OUTPUT="Instance group $INSTANCE_GROUP does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

settings_instance_group () {
    TOPIC="Settings instance group"
    ERROR=-1
    OUTPUT="Setting instance group $INSTANCE_GROUP"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # enables the autoscaling for the loadbalancer instance group

    EXTRA=$(gcloud compute instance-groups managed set-autoscaling $INSTANCE_GROUP --region $REGION --max-num-replicas $INSTANCE_GROUP_MAX_REPLICAS \
        --target-cpu-utilization $INSTANCE_GROUP_TARGET_CPU_UTIL 2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error setting instance group $INSTANCE_GROUP"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Instance group $INSTANCE_GROUP settings set"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    # sets the named ports for the instance group

    EXTRA=$(gcloud compute instance-groups set-named-ports $INSTANCE_GROUP --named-ports=http:5000 --region $REGION  2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error setting instance group $INSTANCE_GROUP"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Instance group $INSTANCE_GROUP settings set"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}