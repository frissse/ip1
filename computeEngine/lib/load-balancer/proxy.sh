#!/usr/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

# checks to see if the parts needed to create the proxy are present or not

check_url_map () {
    if ! gcloud compute url-maps list --quiet 2>&1 | grep -w "$URL_MAP" 2>&1 /dev/null; then
        return 0
    else
        return 1
    fi
}

check_lb_proxy () {
    if ! gcloud compute target-https-proxies list --quiet 2>&1| grep -w "$PROXY_HTTPS" > /dev/null; then
        return 0
    else
        return 1
    fi
}

check_ssl_policy () {
    if ! gcloud compute ssl-policies list --quiet 2>&1 | grep -w phygital-ssl-policy > /dev/null; then
        return 0
    else
        return 1
    fi
}

create_lb_proxy () {
    TOPIC="Create load balancer proxy"
    ERROR=-1
    OUTPUT="Creating load balancer proxy $PROXY_HTTPS"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # uses the checks to see if the part exists if not creates it
    # 1. url map 2. load balancer proxy 3. ssl policy 4. updates the load balancer proxy

    if check_url_map > /dev/null; then
        EXTRA=$(gcloud compute url-maps create $URL_MAP \
            --default-service $LB_BACKEND  2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating Url map $URL_MAP"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Url map $URL_MAP created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        OUTPUT="Url map $URL_MAP already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_lb_proxy &> /dev/null; then
        EXTRA=$(gcloud compute target-https-proxies create $PROXY_HTTPS \
            --url-map=$URL_MAP \
            --ssl-certificates=$SSL_CERTIFICATE --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating Load balancer proxy $PROXY_HTTPS"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Load balancer proxy $PROXY_HTTPS created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        OUTPUT="Load balancer proxy $PROXY_HTTPS already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_ssl_policy &> /dev/null; then
        EXTRA=$(gcloud compute ssl-policies create phygital-ssl-policy \
            --profile MODERN \
            --min-tls-version 1.0 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating SSL policy phygital-ssl-policy"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="SSL policy phygital-ssl-policy created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi

    else
        OUTPUT="SSL policy phygital-ssl-policy already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute target-https-proxies update $PROXY_HTTPS --ssl-policy phygital-ssl-policy 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error updating Load balancer proxy $PROXY_HTTPS"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Load balancer proxy $PROXY_HTTPS updated"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi
    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_lb_proxy () {
    TOPIC="Delete load balancer proxy"
    ERROR=-1
    OUTPUT="Deleting load balancer proxy $PROXY_HTTPS"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # deletes the parts created by the create_lb_proxy function
    # check if exists, if so deletes it

    if ! check_lb_proxy &> /dev/null; then
        EXTRA=$(gcloud compute target-https-proxies delete $PROXY_HTTPS --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting Load balancer proxy $PROXY_HTTPS"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Load balancer proxy $PROXY_HTTPS deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Load balancer proxy $PROXY_HTTPS does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_ssl_policy &> /dev/null; then
        EXTRA=$(gcloud compute ssl-policies delete phygital-ssl-policy --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting SSL policy phygital-ssl-policy"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="SSL policy phygital-ssl-policy deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="SSL policy phygital-ssl-policy does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_url_map &> /dev/null; then
        EXTRA=$(gcloud compute url-maps delete $URL_MAP --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting Url map $URL_MAP"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Url map $URL_MAP deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Url map $URL_MAP does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}