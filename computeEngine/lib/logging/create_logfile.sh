#!/bin/bash

source $LIB_DIR/logging/set_time_date.sh
source $LIB_DIR/logging/write-to-screen.sh
source $LIB_DIR/logging/write-log-file.sh

set_time_date

check_log_folder () {
    TOPIC="Check log folder"
    OUTPUT="Checking if log folder exists"
    ERROR=-1

    write_to_screen $TOPIC $OUTPUT $ERROR

    if [ ! -d $LOG_DIR ]; then
        mkdir $LOG_DIR
        OUTPUT="Log folder does not exist, creating log folder"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Log folder exists"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $OUTPUT $ERROR
}

create_logfile () {
    check_log_folder
    if [ ! -f $LOG_DIR/$LOGFILE ]; then
        touch $LOGFILE
    fi
}

start_prompt () {
    OUTPUT="Starting $1 script"
    ERROR=-1
    TOPIC="Start $1 script"

    write_to_screen $TOPIC $OUTPUT $ERROR
    write_log_to_file $TOPIC $ERROR $OUTPUT
}

end_prompt () {
    OUTPUT="$1 script finished"
    ERROR=-1
    

    if [ $1 == "Deploy" ]; then
        TOPIC="End $1 script, you can visit the website at $DOMAIN_NAME"
    fi

    write_to_screen $TOPIC $OUTPUT $ERROR
    write_log_to_file $TOPIC $ERROR $OUTPUT
}