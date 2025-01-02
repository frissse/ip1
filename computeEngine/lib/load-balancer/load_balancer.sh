#!/bin/bash 

# source source_scripts.sh

delete_loadbalancer () {

    # a function that deletes the load balancer at once in the right order

    delete_lb_forwarding_rules

    remove_lb_backend

    delete_lb_proxy

    delete_lb_backend

    delete_instance_group

    delete_health_checks

    delete_firewall_rules

    delete_instance_template
}