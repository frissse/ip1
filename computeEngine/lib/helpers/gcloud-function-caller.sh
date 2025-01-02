#!/bin/bash

source config.sh
source $LIB_DIR/helpers/static_vars.sh
source $LIB_DIR/helpers/overview-gcloud-commands.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

OUTPUT=""

get_command_type () {
    # parameters $2 should say if it is error, info or warning
    MESSAGE_TYPE=$1
    COMMAND_TYPE=$2
    PHASE=$3
    TOPIC=$4
    if [[ $MESSAGE_TYPE == "ERROR" ]]; then
        echo $COMMAND_TYPE
        case $COMMAND_TYPE in
            "CREATE")
                OUTPUT="Error creating $TOPIC"
                ;;
            "UPDATE")
                OUTPUT="Error updating $TOPIC"
                ;;
            "DELETE")
                OUTPUT="Error deleting $TOPIC"
                ;;
            *)
                OUTPUT="Error"
                ;;
        esac
    elif [[ $MESSAGE_TYPE == "INFO" ]]; then
        echo $TOPIC
        case $COMMAND_TYPE in
            "CREATE")
                if [[ $PHASE == "BEFORE" ]]; then
                    OUTPUT="$TOPIC creating"
                else
                    OUTPUT="$TOPIC created"
                fi
                ;;
            "UPDATE")
                if [[ $PHASE == "BEFORE" ]]; then
                    OUTPUT="$TOPIC updating"
                else
                    OUTPUT="$TOPIC updated"
                fi
                ;;
            "DELETE")
                if [[ $PHASE == "BEFORE" ]]; then
                    OUTPUT="$TOPIC deleting"
                else
                    OUTPUT="$TOPIC deleted"
                fi
                ;;
            *)
                OUTPUT="Error"
                ;;
        esac
    else
        OUTPUT="Type not found"
    fi

}

call_gcloud_command () {
    TOPIC=$2
    COMMAND_TYPE=$3
    COMMAND=$1
    ERROR=-1

    echo $COMMAND $TOPIC $TYPE

    get_command_type  "INFO" "$COMMAND_TYPE" "BEFORE"  "$TOPIC"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # EXTRA=$($COMMAND 2>&1)
    # if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
    #     ERROR=1
    #     get_command_type $TYPE "ERROR" $TOPIC
    #     write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    # else
    #     ERROR=0
    #     get_command_type $TYPE "INFO" $TOPIC
    #     write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    # fi

    # write_to_screen $TOPIC $ERROR $OUTPUT

}

