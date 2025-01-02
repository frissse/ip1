#!/usr/bin/bash

source config.sh
source source_scripts.sh

delete_temp_file_from_config
create_temp_file
write_temp_file_to_config

check_database_instance

