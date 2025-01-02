#!/usr/bin/bash

source config.sh
source $LIB_DIR/logging/colors.sh

parse_output () {
    status_width=22 # Max breedte voor de status kolom
    step_width=40   # Max breedte voor de stap kolom

    # Print de regels met specifieke uitlijning
    printf "%-${status_width}s %-${step_width}s %s\n" "${3}[ $4 ]${NC}" "TOPIC: $1" "OUTPUT: $2"
}

parse_user_input () {
    # Print de regels met specifieke uitlijning
    printf "%-${status_width}s %-${step_width}s %s\n" "${2}[ $3 ]${NC}" "$1"
}