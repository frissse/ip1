#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_lb_forwarding_rules () {
    if ! gcloud compute forwarding-rules list --global | grep $FORWARDING_RULE_HTTPS &> /dev/null; then
        return 0
    else
        return 1
    fi
}

create_lb_forwarding_rules () {
    TOPIC="Create load balancer forwarding rules"
    ERROR=-1
    OUTPUT="Creating load balancer forwarding rules $FORWARDING_RULE_HTTPS"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_lb_forwarding_rules &> /dev/null; then
        EXTRA=$(gcloud compute forwarding-rules create $FORWARDING_RULE_HTTPS \
            --load-balancing-scheme=EXTERNAL \
            --network-tier=PREMIUM \
            --address=$LB_STATIC_IP \
            --global \
            --target-https-proxy=$PROXY_HTTPS \
            --ports=443 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating Load balancer forwarding rules $FORWARDING_RULE_HTTPS"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Load balancer forwarding rules $FORWARDING_RULE_HTTPS created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi

    else
        OUTPUT="Load balancer forwarding rules $FORWARDING_RULE_HTTPS already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT 
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_lb_forwarding_rules () {
    TOPIC="Delete load balancer forwarding rules"
    ERROR=-1
    OUTPUT="Deleting load balancer forwarding rules $FORWARDING_RULE_HTTPS"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_lb_forwarding_rules &> /dev/null; then
        EXTRA=$(gcloud compute forwarding-rules delete $FORWARDING_RULE_HTTPS --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Load balancer forwarding rules $FORWARDING_RULE_HTTPS does not exist, skipping"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Load balancer forwarding rules $FORWARDING_RULE_HTTPS deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
        OUTPUT="Load balancer forwarding rules $FORWARDING_RULE_HTTPS deleted"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Load balancer forwarding rules $FORWARDING_RULE_HTTPS does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}