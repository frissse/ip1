#!/bin/bash

scripts=(
    "config.sh"
    "lib/bucket/bucket.sh"
    "lib/database/database.sh"
    "lib/firewall/firewall.sh"
    "lib/instance/instance.sh"
    "lib/instance/instance_template.sh"
    "lib/load-balancer/backend.sh"
    "lib/load-balancer/forwarding_rules.sh"
    "lib/load-balancer/health_check.sh"
    "lib/load-balancer/instance_group.sh"
    "lib/load-balancer/load_balancer.sh"
    "lib/load-balancer/proxy.sh"
    "lib/load-balancer/ssl_certificate.sh"
    "lib/logging/colors.sh"
    "lib/logging/create_logfile.sh"
    "lib/logging/info_dns.sh"
    "lib/logging/parse_output.sh"
    "lib/logging/set_time_date.sh"
    "lib/logging/write-log-file.sh"
    "lib/logging/write-to-screen.sh"
    "lib/network/network.sh"
    "lib/prerequisites/config_values.sh"
    "lib/prerequisites/create_tempfiles.sh"
    "lib/project/project.sh"    
    "lib/secrets/secrets.sh"
    "lib/upgrade/upgrade_functions.sh"
    "lib/deploy-functions/deploy-functions.sh"
    "lib/delete-functions/delete-functions.sh"
    "lib/settings-functions/settings-functions.sh"
)

for script in "${scripts[@]}"; do
    source $script
done