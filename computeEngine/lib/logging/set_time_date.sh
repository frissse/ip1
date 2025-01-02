#!/usr/bin/bash

function set_time_date () {
    export DATE=$(date +%Y%m%d)
    export TIME=$(date +%H%M)
    export LOGFILE=$LOG_DIR/logfile_"$DATE"_"$TIME".txt
    export PREFIX="$DATE $TIME"
}

