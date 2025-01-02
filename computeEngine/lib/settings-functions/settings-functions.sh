#!/bin/bash 

source config.sh

choose_option () {
    OUTPUT="Choose option: 1) database backups 2) project settings 3) instance group settings 4) exit"
    ERROR=-2
    write_to_screen $TOPIC $OUTPUT $ERROR
    read OPTION
    case $OPTION in
        1) database_backups;;
        2) choice_project_settings;;
        3) update_instance_group;;
        4) exit;;
        *) ERROR=-1
           OUTPUT="Invalid option"
           write_to_screen $TOPIC $OUTPUT $ERROR
           choose_option;;
    esac

}

database_backups () {
    choice_database_backup_option
}

choice_project_settings () {
    TOPIC="Profile settings"
    ERROR=-1
    OUTPUT="Starting profile settings"

    write_to_screen $TOPIC $ERROR $OUTPUT

    OUTPUT="Select the setting you want to change 1) set default profile 2) set default compute region"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT

    read SETTING_TYPE

    if [[ ! $SETTING_TYPE =~ ("1"|"2") ]]; then
        OUTPUT="Error selecting setting type"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR
    else
        OUTPUT="Setting type selected"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        ERROR=0
        case $SETTING_TYPE in
            "1")
                set_default_profile
                ;;
            "2")
                set_default_compute_region
                ;;
        esac
    fi

}


update_instance_group () {
    TOPIC="Update instance group"
    ERROR=-1
    OUTPUT="Updating instance group"
    write_to_screen $TOPIC $ERROR $OUTPUT


    OUTPUT="Select the update you want to perform 1) enable Cloud CDN 2) disable Cloud CDN 3) upgrade max replicas 4) exit"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read UPDATE_TYPE

    if [[ ! $UPDATE_TYPE =~ ("1"|"2"|"3"|"4"|"5") ]]; then
        OUTPUT="Error selecting update type"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR
    else
        OUTPUT="Update type selected"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        ERROR=0
        case $UPDATE_TYPE in
            "1")
                enable_cloud_cdn
                ;;
            "2")
                disable_cloud_cdn
                ;;
            "3")
                upgrade_min_replicas
                ;;
            "4")
                exit
                ;;
        esac
    fi
}

enable_cloud_cdn () {
    TOPIC="Enable Cloud CDN"
    ERROR=-1
    OUTPUT="Enabling Cloud CDN"

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute backend-services update $LB_BACKEND --enable-cdn --global 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error enabling Cloud CDN"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Cloud CDN enabled"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

disable_cloud_cdn () {
    TOPIC="Disable Cloud CDN"
    ERROR=-1
    OUTPUT="Disabling Cloud CDN"

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute backend-services update $LB_BACKEND --no-enable-cdn --global 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error disabling Cloud CDN"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Cloud CDN disabled"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
} 

upgrade_min_replicas () {
    TOPIC="Upgrade number of replicas"
    ERROR=-1
    OUTPUT="Upgrading number replicas"

    write_to_screen $TOPIC $ERROR $OUTPUT

    OUTPUT="Please enter the amount of replicas you want to upgrade to:"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read NEW_MIN_REPLICAS

    EXTRA=$(gcloud compute instance-groups managed set-autoscaling $INSTANCE_GROUP --max-num-replicas $INSTANCE_GROUP_MAX_REPLICAS --min-num-replicas $NEW_MIN_REPLICAS --region=$REGION 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error upgrading max replicas"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Max replicas upgraded"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}