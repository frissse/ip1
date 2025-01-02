#!/bin/bash

source config.sh

# aggregation into seperate functions to be able to delete certain part of the deployment, or full delete

choice_delete_options () {
    OUTPUT="Choose deletion option: 1) full deletion 2) delete project 3) delete storage 4) delete network 5) delete load balancer 6) delete database 7) database backups"
    ERROR=-2
    write_to_screen $TOPIC $OUTPUT $ERROR
    read DELETE_OPTION
    case $DELETE_OPTION in
        1) full_delete;;
        2) delete_project;;
        3) delete_storage;;
        4) delete_network;;
        5) delete_load_balancer;;
        6) delete_database_infra;;
        *) ERROR=-1
           OUTPUT="Invalid option"
           write_to_screen $TOPIC $OUTPUT $ERROR
           choice_delete_options;;
    esac
}

full_delete () {
    DATABASE_NAME=""

    if [[ $DATABASE_CHOICE == "private" ]]; then
        DATABASE_NAME=$DATABASE_NAME_PRIVATE
    else
        DATABASE_NAME=$DATABASE_NAME_PUBLIC
    fi
    if ! check_database_instance $DATABASE_NAME; then 
        OUTPUT="Do you want to delete the database? (y/n)" 
        ERROR=-2
        write_to_screen $TOPIC $OUTPUT $ERROR
        read DELETE_DATABASE
        if [[ $DELETE_DATABASE == "y" ]]; then
            delete_load_balancer
            delete_storage
            delete_database_infra
            delete_network_infra
            disable_apis
            unlink_billing_account
        else
            delete_load_balancer
            delete_storage
            delete_redis_server
            delete_network_infra
        fi
    fi
}

delete_project () {
    choose_project
    delete_project
}

delete_storage () {
    delete_cloud_bucket
}

delete_network_infra () {
    delete_firewall_rules
    delete_static_ip_lb
    check_cloudflare_dns_record
    delete_allocated_ip_range
    delete_private_access
    delete_network
}

delete_load_balancer () {
    delete_lb_forwarding_rules
    remove_lb_backend
    delete_lb_proxy
    delete_ssl_certificate
    delete_lb_backend
    delete_instance_group
    delete_health_checks
    delete_firewall_rules
    delete_instance_template
}

delete_database_infra () {
    delete_database
    delete_redis_server
}