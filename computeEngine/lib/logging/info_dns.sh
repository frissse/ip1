#!/usr/bin/bash

source config.sh
source $LIB_DIR/network/static-ip.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

info_dns_record () {
    TOPIC="DNS record"
    ERROR=-1
    get_static_ip_lb
    OUTPUT="Don't forget to create a DNS record for $DOMAIN_NAME pointing to $LB_STATIC_IP"
    write_to_screen $TOPIC $ERROR $OUTPUT
}