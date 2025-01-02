#!/bin/bash

source config.sh

amount_of_instances=0
instance_names=()
zones=()

select_branch () {
    TOPIC="Select branch to update"
    ERROR=-1
    OUTPUT="Selecting branch to update"

    write_to_screen $TOPIC $ERROR $OUTPUT

    OUTPUT="Please enter the branch you want to update/deploy: 1) main 2) deployment"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read BRANCH_NAME
    if  [[ ! $BRANCH_NAME =~ ("1"|"2") ]]; then
        OUTPUT="Error selecting branch to update"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Branch selected"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        if [[ $BRANCH_NAME == "1" ]]; then
            BRANCH_NAME="main"
        else
            BRANCH_NAME="deployment"
        fi
        
        sed -i'' -e "s/^BRANCH_NAME=.*/BRANCH_NAME=\"$BRANCH_NAME\"/g" "$TEMP_FILE"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

get_amount_instances() {
    TOPIC="Get amount of instances"
    ERROR=-1
    OUTPUT="Getting amount of instances"

    write_to_screen $TOPIC $ERROR $OUTPUT
    EXTRA=$(gcloud compute instances list --format="value(name)" | wc -l 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error getting amount of instances"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Amount of instances found"
        amount_of_instances=$EXTRA
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

get_instance_names() {
    TOPIC="Get instance names"
    ERROR=-1
    OUTPUT="Getting instance names"

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute instances list --format="value(name)" 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error getting instance names"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Instance names found"
        instance_names=($EXTRA)
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

get_instance_zones() {
    TOPIC="Get instance zones"
    ERROR=-1
    OUTPUT="Getting instance zones"

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute instances list --format="value(zone)" 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error getting instance zones"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Instance zones found"
        zones=($EXTRA)
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

update_code() {
    TOPIC="Upgrade Instances"
    ERROR=-1
    OUTPUT="Upgrading instances"

    write_to_screen $TOPIC $ERROR $OUTPUT

    select_branch
    show_content_temp_file
    delete_secrets
    create_secrets
    get_amount_instances
    get_instance_names
    get_instance_zones

    if [[ $amount_of_instances -eq 0 ]]; then
        OUTPUT="No instances found"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
        write_to_screen $TOPIC $ERROR $OUTPUT
    else 
        for ((i=0; i<$amount_of_instances; i++)); do
            name=${instance_names[$i]}
            zone=${zones[$i]}
            OUTPUT="Upgrading instance $name in zone $zone"
            write_to_screen $TOPIC $ERROR $OUTPUT
            
            string_amount=$(echo $amount_of_instances 2>&1 | tr -d ' ')
            OUTPUT="upgrade instance # $(($i+1)) of $string_amount"
            write_to_screen $TOPIC $ERROR $OUTPUT
            
            EXTRA=$(gcloud compute scp --recurse $LIB_DIR/upgrade/  --project $PROJECT_NAME --zone $zone $name: 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error copying upgrade scrupt to $name in zone $zone"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT
            else
                OUTPUT="File copied to Instance $name in zone $zone"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
            EXTRA=$(gcloud compute ssh --project $PROJECT_NAME --zone $zone --command="sudo bash /home/alex/upgrade/upgrade-instance.sh" $name 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error upgrading instance $name in zone $zone"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT
            else
                OUTPUT="Instance $name in zone $zone upgraded"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
        done
    fi
}

update_env_vars () {
    TOPIC="Update environment variables"
    ERROR=-1
    OUTPUT="Updating environment variables"

    write_to_screen $TOPIC $ERROR $OUTPUT

    get_user
    get_service_account

    if [[ $DATABASE_CHOICE == "private" ]]; then
        get_ip_private_database
        write_redis_ip_to_file
    else
       get_ip_database
        write_redis_ip_to_file
    fi
    show_content_temp_file
    delete_secrets
    create_secrets
    get_amount_instances
    get_instance_names
    get_instance_zones

    if [[ $amount_of_instances -eq 0 ]]; then
        OUTPUT="No instances found"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
        write_to_screen $TOPIC $ERROR $OUTPUT
    else 
        for ((i=0; i<$amount_of_instances; i++)); do
            name=${instance_names[$i]}
            zone=${zones[$i]}
            OUTPUT="Upgrading environment variabels in VM with name: $name in zone $zone"
            write_to_screen $TOPIC $ERROR $OUTPUT
            
            string_amount=$(echo $amount_of_instances 2>&1 | tr -d ' ')
            OUTPUT="upgrading instance # $(($i+1)) of $string_amount"
            write_to_screen $TOPIC $ERROR $OUTPUT
            
            EXTRA=$(gcloud compute scp $LIB_DIR/upgrade/upgrade_env_vars.sh  --project $PROJECT_NAME --zone $zone $name: 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error copying upgrade scrupt to $name in zone $zone"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT
            else
                OUTPUT="File copied to Instance $name in zone $zone"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
            EXTRA=$(gcloud compute ssh --project $PROJECT_NAME --zone $zone --command="sudo bash /home/alex/upgrade/upgrade_env_vars.sh" $name 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error upgrading instance $name in zone $zone"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT
            else
                OUTPUT="Instance $name in zone $zone upgraded"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
        done
    fi

}

select_update_type () {
    TOPIC="Select update type"
    ERROR=-1
    OUTPUT="Selecting update type"

    write_to_screen $TOPIC $ERROR $OUTPUT

    get_user
    get_service_account
    get_ip_private_database
    write_redis_ip_to_file

    OUTPUT="Please enter the update type: 1) update code 2) update env vars 3) update specs 4) update instance group"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read UPDATE_TYPE

    if [[ ! $UPDATE_TYPE =~ ("1"|"2"|"3"|"4") ]]; then
        OUTPUT="Error selecting update type"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Update type selected"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        ERROR=0
        case $UPDATE_TYPE in
            "1")
                update_code
                ;;
            "2")
                update_env_vars
                ;;
            "3")
                options_for_updates
                ;;
            "4") 
                update_instance_group
                ;;
        esac
    fi

}

options_for_updates () {
    TOPIC="Options for updates"
    ERROR=-1
    OUTPUT="Options for updates"

    write_to_screen $TOPIC $ERROR $OUTPUT

    OUTPUT="Please enter the update template: 1) performant 2) larger storage 3) set back to basic"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read UPDATE_TYPE

    if [[ ! $UPDATE_TYPE =~ ("1"|"2"|"3") ]]; then
        OUTPUT="Error selecting update type"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Update type selected"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        ERROR=0
        case $UPDATE_TYPE in
            "1")
                upgrade_to_performant
                ;;
            "2")
                update_to_larger_storage
                ;;
            "3")
                back_to_basic
                ;;
        esac
    fi
}

create_performant_template () {
    TOPIC="Create performant template"
    ERROR=-1
    OUTPUT="Creating performant template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute instance-templates create performant-template \
    --project=$PROJECT_NAME \
    --network=$NETWORK_NAME \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --machine-type=$PERFORMANT_MACHINE_TYPE \
    --service-account=$SERVICE_ACCOUNT \
    --create-disk=auto-delete=yes,boot=yes,device-name=physical-instance-test,image=$IMAGE,mode=rw,size=10,type=pd-ssd \
    --metadata-from-file startup-script=./startup-script.sh \
    --tags dotnet-instance,http-server,https-server 2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error creating performant template"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Performant template created"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

create_storage_template () {
    TOPIC="Create storage template"
    ERROR=-1
    OUTPUT="Creating storage template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    echo "Please enter the disk size (in GB):"
    read DISK_SIZE

    EXTRA=$(gcloud compute instance-templates create $STORAGE_TEMPLATE_NAME \
    --project=$PROJECT_NAME \
    --network=$NETWORK_NAME \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --machine-type=$MACHINE_TYPE \
    --service-account=$SERVICE_ACCOUNT \
    --create-disk=auto-delete=yes,boot=yes,device-name=physical-instance-test,image=$IMAGE,mode=rw,size=$DISK_SIZE,type=pd-balanced \
    --metadata-from-file startup-script=./startup-script.sh \
    --tags dotnet-instance,http-server,https-server 2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error creating storage template"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Storage template created"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

upgrade_to_performant () {
    TOPIC="Upgrade instance groups to performant template"
    ERROR=-1
    OUTPUT="Upgrading instance groups to performant template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    create_performant_template

    EXTRA=$(gcloud compute instance-groups managed set-instance-template $INSTANCE_GROUP --template performant-template --region $REGION 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error upgrading instance groups to performant template"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Instance groups upgraded to performant template"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

upgrade_to_larger_storage () {
    TOPIC="Upgrade instance groups to storage template"
    ERROR=-1
    OUTPUT="Upgrading instance groups to storage template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    create_storage_template

    EXTRA=$(gcloud compute instance-groups managed set-instance-template $INSTANCE_GROUP_NAME --template=$STORAGE_TEMPLATE_NAME --zone=$ZONE 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error upgrading instance groups to storage template"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Instance groups upgraded to storage template"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

back_to_basic () {
    TOPIC="Upgrade instance groups to basic template"
    ERROR=-1
    OUTPUT="Upgrading instance groups to basic template"

    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud compute instance-groups managed set-instance-template $INSTANCE_GROUP --template=$BASIC_TEMPLATE_NAME --region $REGION 2>&1)
    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error upgrading instance groups to basic template"
        ERROR=1
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    else
        OUTPUT="Instance groups upgraded to basic template"
        ERROR=0
        write_log_to_file $TOPIC $OUTPUT $ERROR $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}
