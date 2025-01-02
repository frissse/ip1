#!/usr/bin/bash

source config.sh

write_log_to_file () {
    #check if $ERROR is either 1 or 0
    if [[ $ERROR -eq 1 ]]; then
        echo "$PREFIX [ ERROR ] Topic: $TOPIC - $OUTPUT Extra: $EXTRA" >> "$LOGFILE"
    elif [[ $ERROR -eq 0 ]]; then
        echo "$PREFIX [ SUCCESS ] $TOPIC - $OUTPUT Extra: $EXTRA" >> "$LOGFILE"
    else
        echo "$PREFIX [ INFO ] $TOPIC - $OUTPUT Extra: $EXTRA" >> "$LOGFILE"
    fi
}