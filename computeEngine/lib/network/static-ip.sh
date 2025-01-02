#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_static_ip_lb () {
    if ! gcloud compute addresses list | grep $STATIC_IP_NAME 2>&1 /dev/null; then
        return 0
    else
        return 1
    fi
}

create_static_ip_lb () {
    TOPIC="Create static ip"
    ERROR=-1
    OUTPUT="Creating static ip $STATIC_IP_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # get the static ip address for the load balancer

    if check_static_ip_lb > /dev/null; then
        EXTRA=$(gcloud compute addresses create $STATIC_IP_NAME \
            --ip-version=IPV4 \
            --network-tier=PREMIUM \
            --global 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating static ip $STATIC_IP_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Static ip $STATIC_IP_NAME created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi

    else
        OUTPUT="Static ip $STATIC_IP_NAME already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_static_ip_lb () {
    TOPIC="Delete static ip"
    ERROR=-1
    OUTPUT="Deleting static ip $STATIC_IP_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_static_ip_lb &> /dev/null; then
        EXTRA=$(gcloud compute addresses delete $STATIC_IP_NAME --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting static ip $STATIC_IP_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Static ip $STATIC_IP_NAME deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Static ip $STATIC_IP_NAME does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

get_static_ip_lb () {
    TOPIC="Get static ip"
    ERROR=-1
    OUTPUT="Getting static ip $STATIC_IP_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # gets the static IP and writes it to config file

    LB_STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME --global --format="value(address)" 2>&1)
    if [ $? -eq 0 ]; then
        OUTPUT="Static ip $LB_STATIC_IP found"
        ERROR=0
        write_log_to_file  $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Static ip $LB_STATIC_IP not found"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    write_IP_to_file $LB_STATIC_IP

    if [ $? -eq 0 ]; then
        OUTPUT="Static ip $LB_STATIC_IP written to file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Static ip $LB_STATIC_IP not written to file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

write_IP_to_file () {
    IP=$1
    TOPIC="Write IP to file"
    ERROR=-1
    OUTPUT="Writing IP to file"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! cat config.sh | grep -w "LB_STATIC_IP" > /dev/null; then
        TO_WRITE="LB_STATIC_IP=\"$IP\""
        echo "$TO_WRITE" | tee -a config.sh > /dev/null
        OUTPUT="IP written to file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="IP already written to file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}   

#wget requests for cloudflare api

generate_wget_create_request()
{
  cat <<EOF
wget --method POST --header 'Content-Type: application/json' --header 'X-Auth-Email: awaumans@me.com' --header 'X-Auth-Key: $CLOUDFLARE_API_TOKEN' --body-data '{"type": "A", "name": "$DOMAIN_NAME", "content": "$LB_STATIC_IP", "ttl": 60, "proxied": false}' https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/ 
EOF

}

generate_wget_get_request () {
    cat <<EOF
wget --quiet --method GET  --header 'Content-Type: application/json' --header 'X-Auth-Email: awaumans@me.com' --header 'X-Auth-Key: $CLOUDFLARE_API_TOKEN' --output-document dns-records.json https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records
EOF
}

write_dns_record_to_file () {
    TOPIC="Write DNS record to file"
    ERROR=-1
    OUTPUT="Writing DNS record to file"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # gets the DNS record ID for the domain name specified in the config file and writes it to config file

    if ! cat config.sh | grep -w "DNS_RECORD_ID"; then
        DNS_RECORD_ID=$(cat dns-records.json | jq -r '.result[] | select(.name == "'"$DOMAIN_NAME"'") | .id' | tr -d '"')
        TO_WRITE="DNS_RECORD_ID=\"$DNS_RECORD_ID\""
        if ! cat config.sh | grep -w "DNS_RECORD_ID"; then
            echo "$TO_WRITE" 2>&1 | cat >> config.sh 2>&1
        else
            OUTPUT="DNS record ID already written to file"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="DNS record already written to file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

        

    write_to_screen $TOPIC $ERROR $OUTPUT
}


check_cloudflare_dns_record () {
    TOPIC="Check DNS record"
    ERROR=-1
    OUTPUT="Checking if DNS record exists for $DOMAIN_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT
    COMMAND=$(generate_wget_get_request)
    eval "$COMMAND" 2>&1

    # gets the dns records based on the Cloudflare zone ID and writes it to a file
    # checks if the domain name is in the dns records
    # if it is, it asks the user if they want to update or delete the record

    if [[ $(cat dns-records.json) =~ $DOMAIN_NAME ]]; then
        OUTPUT="DNS record exists for $DOMAIN_NAME"
        ERROR=0
        write_to_screen $TOPIC $ERROR $OUTPUT
        
        OUTPUT="What do you want to do? 1. Update 2. Delete 3. Write to file"
        ERROR=-2
        write_to_screen $TOPIC $ERROR $OUTPUT
        read ACTION

        if [ $ACTION == "1" ]; then
            update_cloudflare_dns_record 2>&1
        elif [ $ACTION == "2" ]; then
            delete_cloudflare_dns_record 2>&1
        elif [ $ACTION == "3" ]; then
            write_dns_record_to_file 2>&1
        fi
    else
        OUTPUT="DNS record does not exist for $DOMAIN_NAME"
        ERROR=1
        write_to_screen $TOPIC $ERROR $OUTPUT

        OUTPUT="Want to create a DNS record for $DOMAIN_NAME? y/n"
        ERROR=-2
        write_to_screen $TOPIC $ERROR $OUTPUT
        read CREATE_RECORD
        if [ $CREATE_RECORD == "y" ]; then
            create_cloudflare_dns_record 2>&1
        else
            OUTPUT="Skipping DNS record creation for $DOMAIN_NAME"
            ERROR=1
            write_to_screen $TOPIC $ERROR $OUTPUT
        fi
    fi

    rm -f dns-records.json
}


create_cloudflare_dns_record () {
    TOPIC="Create DNS record"
    ERROR=-1
    OUTPUT="Creating DNS record for $DOMAIN_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT
    COMMAND=$(generate_wget_create_request 2>&1)
    EXTRA=$(eval "$COMMAND" 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        ERROR=1
        OUTPUT="Error creating DNS record for $DOMAIN_NAME"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        ERROR=0
        OUTPUT="DNS record created for $DOMAIN_NAME"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi
}

update_cloudflare_dns_record () {
    TOPIC="Update DNS record"
    ERROR=-1
    OUTPUT="Updating DNS record for $DOMAIN_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT
    
    python3 $LIB_DIR/network/update_dns_record.py $CLOUDFLARE_ACCOUNT_EMAIL $CLOUDFLARE_API_TOKEN $CLOUDFLARE_ZONE_ID $DNS_RECORD_ID $LB_STATIC_IP $DOMAIN_NAME 2>&1 

    if [ $? -eq 0 ]; then
        ERROR=0
        OUTPUT="DNS record updated for $DOMAIN_NAME"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Error updating DNS record for $DOMAIN_NAME"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

delete_cloudflare_dns_record () {
    TOPIC="Delete DNS record"
    ERROR=-1
    OUTPUT="Deleting DNS record for $DOMAIN_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! cat config.sh | grep -w "LB_STATIC_IP" > /dev/null; then
        ERROR=1
        OUTPUT="Static IP not found in config.sh"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        get_static_ip_lb 2>&1
    fi

    if ! cat config.sh | grep -w "DNS_RECORD_ID" > /dev/null; then
        ERROR=1
        OUTPUT="DNS record ID not found in config.sh"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        write_dns_record_to_file 2>&1
    fi

    if ! cat config.sh | grep -w "DOMAIN_NAME" > /dev/null; then
        ERROR=1
        OUTPUT="Domain name not found in config.sh"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    EXTRA=$(python3 $LIB_DIR/network/delete_dns_record.py $CLOUDFLARE_ACCOUNT_EMAIL $CLOUDFLARE_API_TOKEN $CLOUDFLARE_ZONE_ID $DNS_RECORD_ID $LB_STATIC_IP $DOMAIN_NAME 2>&1)
    if [[ $? -eq 1 ]]; then
        ERROR=1
        OUTPUT="Error deleting DNS record for $DOMAIN_NAME"
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        ERROR=0
        
    else
        OUTPUT="DNS record deleted for $DOMAIN_NAME"
        write_to_screen $TOPIC $ERROR $OUTPUT
        OUTPUT="Do you want to creata new DNS record for $DOMAIN_NAME? y/n"
        ERROR=-2
        write_to_screen $TOPIC $ERROR $OUTPUT
        read CREATE_RECORD
        if [ $CREATE_RECORD == "y" ]; then
            create_cloudflare_dns_record 2>&1
        else
            OUTPUT="Skipping DNS record creation for $DOMAIN_NAME"
            ERROR=0
            write_to_screen $TOPIC $ERROR $OUTPUT
        fi 
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}