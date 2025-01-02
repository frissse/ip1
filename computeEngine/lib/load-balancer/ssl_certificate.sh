#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh  

check_ssl_certificate () {
    if ! gcloud compute ssl-certificates list 2>&1 | grep $SSL_CERTIFICATE 2>&1 /dev/null; then
        return 0
    else
        return 1
    fi
}

create_ssl_certificate () {
    TOPIC="Create ssl certificate"
    ERROR=-1
    OUTPUT="Creating ssl certificate $SSL_CERTIFICATE"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_ssl_certificate &> /dev/null; then
        EXTRA=$(gcloud compute ssl-certificates create $SSL_CERTIFICATE --domains=$DOMAIN_NAME --global 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating SSL certificate $SSL_CERTIFICATE"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="SSL certificate $SSL_CERTIFICATE created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        OUTPUT="SSL certificate $SSL_CERTIFICATE already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
       
        OUTPUT="Do you want to update the certificate? (y/n)"
        ERROR=-2
        write_to_screen $TOPIC $ERROR $OUTPUT
        read UPDATE_CERTIFICATE
        
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_ssl_certificate () {
    TOPIC="Delete ssl certificate"
    ERROR=-1
    OUTPUT="Deleting ssl certificate $SSL_CERTIFICATE"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_ssl_certificate > /dev/null; then
        EXTRA=$(gcloud compute ssl-certificates delete $SSL_CERTIFICATE --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting SSL certificate $SSL_CERTIFICATE"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="SSL certificate $SSL_CERTIFICATE deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="SSL certificate $SSL_CERTIFICATE does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

