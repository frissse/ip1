#!/usr/bin/bash
 
source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_network () {
    if ! gcloud compute networks list | grep $NETWORK_NAME &> /dev/null; then
        return 0;
    else 
        return 1;
    fi
}

create_network () {
    TOPIC="Create network"
    ERROR=-1
    OUTPUT="Creating network $NETWORK_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_network; then
        EXTRA=$(gcloud compute networks create $NETWORK_NAME --bgp-routing-mode=global 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating network $NETWORK_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Network $NETWORK_NAME created"
            ERROR=0
            enable_private_service_access
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else 
        ERROR=1
        OUTPUT="Network $NETWORK_NAME already exists"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

create_subnet () {
    TOPIC="Create subnet"
    ERROR=-1
    OUTPUT="Creating subnet $SUBNET_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! gcloud compute networks subnets list --network $NETWORK_NAME | grep $SUBNET_NAME &> /dev/null; then
        EXTRA=$(gcloud compute networks subnets create $SUBNET_NAME \
            --network $NETWORK_NAME \
            --range 10.0.0.0/28 \
            --enable-private-ip-google-access 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating subnet $SUBNET_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Subnet $SUBNET_NAME created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        ERROR=1
        OUTPUT="Subnet $SUBNET_NAME already exists"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

enable_private_service_access () {
    TOPIC="Enable private service access"
    ERROR=-1
    OUTPUT="Enabling private service access for $NETWORK_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT


    EXTRA=$(gcloud compute addresses create $PRIVATE_ACCESS \
        --global \
        --purpose=VPC_PEERING \
        --prefix-length=16 \
        --network=projects/$PROJECT_NAME/global/networks/$NETWORK_NAME 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error enabling private service access for $NETWORK_NAME"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Private service access enabled for $NETWORK_NAME"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
        
}

delete_private_access () {
    TOPIC="Delete private access"
    ERROR=-1
    OUTPUT="Deleting private access $PRIVATE_ACCESS"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if gcloud compute addresses list --global | grep $PRIVATE_ACCESS &> /dev/null; then
        EXTRA=$(gcloud compute addresses delete $PRIVATE_ACCESS --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting private access $PRIVATE_ACCESS"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Private access $PRIVATE_ACCESS deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        ERROR=1
        OUTPUT="Private access $PRIVATE_ACCESS does not exist"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
    write_to_screen $TOPIC $ERROR $OUTPUT

}

delete_network () {
    TOPIC="Delete network"
    ERROR=-1
    OUTPUT="Deleting network $NETWORK_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT
    
    if ! check_network; then
        EXTRA=$(gcloud compute networks delete $NETWORK_NAME --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting network $NETWORK_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Network $NETWORK_NAME deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi

        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Network $NETWORK_NAME does not exist"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
} 

create_allocated_ip_range () {
    TOPIC="Create allocated ip range"
    ERROR=-1
    OUTPUT="Creating allocated ip range $ALLOCATED_IP_RANGE_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! gcloud compute addresses list --global | grep $ALLOCATED_IP_RANGE_NAME &> /dev/null; then
        EXTRA=$(gcloud compute addresses create $ALLOCATED_IP_RANGE_NAME \
            --purpose=VPC_PEERING \
            --global \
            --prefix-length 24 \
            --network=projects/$PROJECT_NAME/global/networks/$NETWORK_NAME \
            --project $PROJECT_NAME 2>&1)

        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating allocated ip range $ALLOCATED_IP_RANGE_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Allocated ip range $ALLOCATED_IP_RANGE_NAME created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
       fi
    else 
        ERROR=1
        OUTPUT="Allocated ip range $ALLOCATED_IP_RANGE_NAME already exists"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud services vpc-peerings connect \
        --service=servicenetworking.googleapis.com \
        --ranges=$ALLOCATED_IP_RANGE_NAME \
        --network=$NETWORK_NAME \
        --project=$PROJECT_NAME 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error connecting allocated ip range $ALLOCATED_IP_RANGE_NAME to network $NETWORK_NAME"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Allocated ip range $ALLOCATED_IP_RANGE_NAME connected to network $NETWORK_NAME"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_allocated_ip_range () {
    TOPIC="Delete allocated ip range"
    ERROR=-1
    OUTPUT="Deleting allocated ip range $ALLOCATED_IP_RANGE_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if gcloud compute addresses list --global | grep $ALLOCATED_IP_RANGE_NAME &> /dev/null; then
        EXTRA=$(gcloud compute addresses delete $ALLOCATED_IP_RANGE_NAME --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting allocated ip range $ALLOCATED_IP_RANGE_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Allocated ip range $ALLOCATED_IP_RANGE_NAME deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        ERROR=1
        OUTPUT="Allocated ip range $ALLOCATED_IP_RANGE_NAME does not exist"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

