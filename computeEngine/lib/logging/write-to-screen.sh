#!/usr/bin/bash

source config.sh
source $LIB_DIR/logging/colors.sh
source $LIB_DIR/logging/parse_output.sh

write_to_screen() {
    if [[ "$ERROR" -eq 1 ]]; then
        parse_output "$TOPIC" "$OUTPUT" $RED "ERROR"
    elif [[ "$ERROR" -eq 0 ]]; then
        parse_output "$TOPIC" "$OUTPUT" $GREEN "SUCCESS"
    elif [[ "$ERROR" -eq -1 ]]; then
        parse_output "$TOPIC" "$OUTPUT" $BLUE "INFO"
    elif [[ "$ERROR" -eq -2 ]]; then
        parse_user_input "$OUTPUT" $WHITE "CHOICE"
    fi
}