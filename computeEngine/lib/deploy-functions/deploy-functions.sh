#!/bin/bash

source config.sh

# a switch case that forwards to the correct aggregation function to deploy fully or partly

choose_deploy_option () {
    OUTPUT="Choose deployment option: 1) full deployment 2) deploy project 3) deploy storage 4) deploy network 5) deploy load balancer 6) deploy database 7) database backups"
    ERROR=-2
    write_to_screen $TOPIC $OUTPUT $ERROR
    read DEPLOY_OPTION
    case $DEPLOY_OPTION in
        1) full_deploy;;
        2) deploy_project;;
        3) deploy_storage;;
        4) deploy_network;;
        5) deploy_load_balancer;;
        6) deploy_database;;
        *) ERROR=-1
           OUTPUT="Invalid option"
           write_to_screen $TOPIC $OUTPUT $ERROR
           choose_deploy_option;;
    esac
}

full_deploy () {
    # remove the variable STATIC_IP from the config.sh file if exists
    FILE=config.sh
    if grep -q "LB_STATIC_IP" config.sh; then
        sed -i '' '/LB_STATIC_IP/d' "$FILE"
    fi
    
    # remove the variable DNS_RECORD from the config.sh file if exists
    if grep -q "DNS_RECORD" config.sh; then
        sed -i '' '/DNS_RECORD/d' "$FILE"
    fi

    # remove the variable USER from the config.sh file if exists
    if grep -q "USER" config.sh; then
        sed -i '' '/USER/d' "$FILE"
    fi

    # remove the variable SERVICE_ACCOUNT from the config.sh file if exists
    if grep -q "SERVICE_ACCOUNT" config.sh; then
        sed -i '' '/SERVICE_ACCOUNT/d' "$FILE"
    fi

    if grep -q "DATABASE_CHOICE" config.sh; then
        sed -i '' '/DATABASE_CHOICE/d' "$FILE"
    fi
    OUTPUT="Enabling SQL Admin API to check if database is deployed or not"
    ERROR=-1
    write_to_screen $TOPIC $OUTPUT $ERROR
    EXTRA=$(gcloud services enable sqladmin.googleapis.com --project=$PROJECT_NAME --quiet 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail")  ]]; then
        OUTPUT="SQL Admin API is already enabled"
        ERROR=-1
        write_to_screen $TOPIC $OUTPUT $ERROR
    else
        OUTPUT="SQL Admin API is enabled"
        ERROR=-1
        write_to_screen $TOPIC $OUTPUT $ERROR
    fi
    if check_database_instance; then 
        OUTPUT="Do you want to deploy the database? (y/n)" 
        ERROR=-2
        write_to_screen $TOPIC $OUTPUT $ERROR
        read DEPLOY_DATABASE
        if [[ $DEPLOY_DATABASE == "y" ]]; then
            deploy_project
            deploy_network
            create_cloud_bucket
            deploy_database
            deploy_load_balancer
        else
            deploy_project
            deploy_network
            create_cloud_bucket
            create_redis_server
            deploy_load_balancer
        fi
    fi
    # deploy_project
    
}

deploy_project () {
    set_default_profile
    get_user
    # create_project
    get_service_account
    check_billing_account
    check_apis
}

deploy_storage () {
    create_cloud_bucket
}

deploy_network () {
    create_network
    create_firewall_rules
    create_static_ip_lb
    get_static_ip_lb
    create_allocated_ip_range
    check_cloudflare_dns_record
}

deploy_load_balancer () {
    get_user
    get_service_account
    get_ip_private_database
    write_redis_ip_to_file
    select_branch
    show_content_temp_file
    delete_secrets
    create_secrets
    create_firewall_rules
    create_instance_template
    create_health_checks
    create_instance_group
    create_lb_backend
    settings_instance_group
    create_ssl_certificate
    create_lb_proxy
    create_lb_forwarding_rules 
    
}

deploy_database () {
    create_redis_server
    choose_public_private_database
}

