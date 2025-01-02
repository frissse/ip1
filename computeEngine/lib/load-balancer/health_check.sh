#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

check_health_checks () {
    if ! gcloud compute health-checks list --global | grep -w "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

create_health_checks () {
    TOPIC="Create health checks"
    ERROR=-1
    OUTPUT="Creating health checks"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_health_checks $HEALTH_CHECK &> /dev/null; then
        EXTRA=$(gcloud compute health-checks create http $HEALTH_CHECK \
            --port 5000 \
            --global \
            --enable-logging \
            --check-interval=$HEALTH_CHECK_INTERVAL \
            --timeout=$HEALTH_CHECK_TIMEOUT  2>&1)
        OUTPUT="Health check $HEALTH_CHECK created"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Health check $HEALTH_CHECK already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi   

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_health_checks () {
    TOPIC="Delete health checks"
    ERROR=-1
    OUTPUT="Deleting health checks"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_health_checks $HEALTH_CHECK &> /dev/null; then
        EXTRA=$(gcloud compute health-checks delete $HEALTH_CHECK --global --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting health check $HEALTH_CHECK"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Health check $HEALTH_CHECK deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    else
        OUTPUT="Health check $HEALTH_CHECK does not exist, skipping"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}