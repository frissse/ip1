#!/bin/bash 

. config.sh
. $LIB_DIR/logging/create_logfile.sh
. $LIB_DIR/logging/write-log-file.sh
. $LIB_DIR/logging/write-to-screen.sh

check_firewall_rule() {
    if ! gcloud compute firewall-rules list | grep $1 > /dev/null ; then
        return 0
    else
        return 1
    fi
}

create_firewall_rules () {
    TOPIC="Create firewall rules"
    ERROR=-1
    OUTPUT="Creating firewall rules"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_firewall_rule $FW_ALLOW_PORT_5000 &> /dev/null ; then 
        EXTRA=$(gcloud compute firewall-rules create $FW_ALLOW_PORT_5000 \
            --network=$NETWORK_NAME \
            --allow tcp:5000 \
            --source-ranges 0.0.0.0/0 \
            --target-tags dotnet-instance 2>&1)
        OUTPUT="Firewall rule $FW_ALLOW_PORT_5000 created"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Firewall rule $FW_ALLOW_PORT_5000 already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_firewall_rule $FW_SSH &> /dev/null; then
        EXTRA=$(gcloud compute firewall-rules create allow-ssh-phygital --direction=INGRESS --priority=1000 --network=$NETWORK_NAME --action=ALLOW --rules=tcp:22 2>&1)
        OUTPUT="Firewall rule $FW_SSH created"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Firewall rule $FW_SSH already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_firewall_rule $FW_HEALTH_CHECK &> /dev/null ; then
        EXTRA=$(gcloud compute firewall-rules create $FW_HEALTH_CHECK \
            --network=$NETWORK_NAME \
            --action=allow \
            --direction=ingress \
            --source-ranges=130.211.0.0/22,35.191.0.0/16 \
            --target-tags=allow-health-check \
            --rules=tcp:80,tcp:5000 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating firewall rule $FW_HEALTH_CHECK"
            ERROR=1
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Firewall rule $FW_HEALTH_CHECK created"
            ERROR=0
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Firewall rule $FW_HEALTH_CHECK already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi 

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_firewall_rule $FW_REDIS &> /dev/null; then 
        EXTRA=$(gcloud compute firewall-rules create $FW_REDIS --network $NETWORK_NAME --allow tcp:6379 2>&1) 
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating firewall rule $FW_REDIS"
            ERROR=1
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Firewall rule $FW_REDIS created"
            ERROR=0
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Firewall rule $FW_REDIS already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_firewall_rules () {
    TOPIC="Delete firewall rules"
    ERROR=-1
    OUTPUT="Deleting firewall rules"

    write_to_screen $TOPIC $ERROR $OUTPUT

    FIREWALLS=($(gcloud compute firewall-rules list --filter="network=$NETWORK_NAME" --format="value(name)"))
    for FIREWALL in "${FIREWALLS[@]}"; do
        EXTRA=$(gcloud compute firewall-rules delete $FIREWALL --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting firewall rule $FIREWALL"
            ERROR=1
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Firewall rule $FIREWALL deleted"
            ERROR=0
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    done

    # if ! check_firewall_rule $FW_ALLOW_PORT_5000; then
    #     EXTRA=$(gcloud compute firewall-rules delete $FW_ALLOW_PORT_5000 --quiet 2>&1)
    #     if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
    #         OUTPUT="Error deleting firewall rule $FW_ALLOW_PORT_5000"
    #         ERROR=1
    #         write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    #     else
    #         OUTPUT="Firewall rule $FW_ALLOW_PORT_5000 deleted"
    #         ERROR=0
    #         write_log_to_file $TOPIC $ERROR $OUTPUT
    #     fi
    # else
    #     ERROR=1
    #     OUTPUT="Firewall rule $FW_ALLOW_PORT_5000 does not exist"
    #     write_log_to_file $TOPIC $ERROR $OUTPUT
    # fi

    # write_to_screen $TOPIC $ERROR $OUTPUT

    # if ! check_firewall_rule $FW_HEALTH_CHECK; then
    #     EXTRA=$(gcloud compute firewall-rules delete $FW_HEALTH_CHECK --quiet 2>&1)
    #     if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
    #         OUTPUT="Error deleting firewall rule $FW_HEALTH_CHECK"
    #         ERROR=1
    #         write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    #     else
    #         OUTPUT="Firewall rule $FW_HEALTH_CHECK deleted"
    #         ERROR=0
    #         write_log_to_file $TOPIC $ERROR $OUTPUT
    #     fi
    # else
    #     ERROR=1
    #     OUTPUT="Firewall rule $FW_HEALTH_CHECK does not exist"
    #     write_log_to_file $TOPIC $ERROR $OUTPUT
    # fi

    # write_to_screen $TOPIC $ERROR $OUTPUT

    # if ! check_firewall_rule $FW_SSH; then
    #     EXTRA=$(gcloud compute firewall-rules delete $FW_SSH --quiet 2>&1)
    #     if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
    #         OUTPUT="Error deleting firewall rule $FW_SSH"
    #         ERROR=1
    #         write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    #     else
    #         OUTPUT="Firewall rule $FW_SSH deleted"
    #         ERROR=0
    #         write_log_to_file $TOPIC $ERROR $OUTPUT
    #     fi
    # else
    #     ERROR=1
    #     OUTPUT="Firewall rule $FW_SSH does not exist"
    #     write_log_to_file $TOPIC $ERROR $OUTPUT
    # fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}