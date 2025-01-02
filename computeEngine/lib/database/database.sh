#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

FORMATTED_BACKUPS=()

choose_public_private_database () {
    TOPIC="Choose public or private database"
    ERROR=-1
    OUTPUT="Choose public or private database"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Ask user to choose public or private database to be created

    OUTPUT="Choose public or private database (1 = private, 2 = public): "
    ERROR=-2
    while [[ $DATABASE_CHOICE -le 0 || $DATABASE_CHOICE -gt 2 ]]; do
        write_to_screen $TOPIC $ERROR $OUTPUT
        read DATABASE_CHOICE
    done

    if [[ $DATABASE_CHOICE -eq 1 ]]; then
        # Create private database instance
        create_private_database_instance

        # get private database IP and write to temp file
        get_ip_private_database
        create_database $DATABASE_NAME_PRIVATE
        #write to config private was selected in a variable
        if ! cat config.sh | grep -w "DATABASE_CHOICE" > /dev/null; then
            TO_WRITE="DATABASE_CHOICE=\"private\""
            echo "$TO_WRITE"  2>&1 | cat >> config.sh 2>&1
            OUTPUT="Writing private database choice to config.sh"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Private database choice already exists in config.sh"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        # Create public database instance
        create_database_instance

        # get public database IP and write to temp file
        get_ip_database
        create_database $DATABASE_INSTANCE_NAME
        #write to config public was selected in a variable
        if ! cat config.sh | grep -w "DATABASE_CHOICE"; then
            TO_WRITE="DATABASE_CHOICE=\"public\""
            echo "$TO_WRITE"  2>&1 | cat >> env-var.txt 2>&1
            OUTPUT="Writing public database choice to config.sh"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="Public database choice already exists in config.sh"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}
check_database_instance () {
    if ! gcloud sql instances list --quiet | grep -w "$1" > /dev/null ; then
        return 0
    else
        return 1
    fi
        
}

get_ip_private_database () {
    TOPIC="Get private database IP"
    ERROR=-1
    OUTPUT="Getting private database IP"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # Get private database IP

    ASPNETCORE_DEV_DATABASE_HOST=$(gcloud sql instances describe $DATABASE_NAME_PRIVATE --format="value(ipAddresses.ipAddress)" | cut -d ';' -f 1)

    if  [ -n "$ASPNETCORE_DEV_DATABASE_HOST" ]; then
        ERROR=0
        OUTPUT="Private database IP found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Private database IP not found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    # Write private database IP to temp file
    if ! cat $TEMP_FILE | grep -w $ASPNETCORE_DEV_DATABASE_HOST &> /dev/null; then
        TO_WRITE="ASPNETCORE_DEV_DATABASE_HOST=\"$ASPNETCORE_DEV_DATABASE_HOST\""
        echo "$TO_WRITE" 2>&1 | cat >> $TEMP_FILE 2>&1
        OUTPUT="Writing service account to temp file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Private database IP already exists in temp file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

get_ip_database () {
    TOPIC="Get database IP"
    ERROR=-1
    OUTPUT="Getting database IP"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # Get public database IP

    ASPNETCORE_DEV_DATABASE_HOST=$(gcloud sql instances describe $DATABASE_INSTANCE_NAME --format="value(ipAddresses.ipAddress)" | cut -d ';' -f 1)

    if  [ -n "$ASPNETCORE_DEV_DATABASE_HOST" ]; then
        ERROR=0
        OUTPUT="Database IP found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Database IP not found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    # Write public database IP to temp file

    if ! cat $TEMP_FILE | grep -w $ASPNETCORE_DEV_DATABASE_HOST &> /dev/null; then
        echo "ASPNETCORE_DEV_DATABASE_HOST=\"$ASPNETCORE_DEV_DATABASE_HOST\"" >> $TEMP_FILE
        OUTPUT="Writing database IP to temp file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Database IP already exists in temp file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    # Write public database IP to config.sh

    if ! cat env-var.txt | grep -w $ASPNETCORE_DEV_DATABASE_HOST &> /dev/null; then
        echo "ASPNETCORE_DEV_DATABASE_HOST=\"$ASPNETCORE_DEV_DATABASE_HOST\"" | tee -a config.sh
        OUTPUT="Writing database IP to config.sh"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Database IP already exists in config.sh"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

check_database () {
    # Check if database exists
    if ! gcloud sql databases list --instance $1 --quiet 2>&1 | grep $ASPNETCORE_DEV_DATABASE_NAME 2>&1; then
        return 0;
    else
        return 1;
    fi
}

create_private_database_instance () {
    TOPIC="Create private database instance"
    ERROR=-1
    OUTPUT="Creating private database instance $DATABASE_NAME_PRIVATE"
    
    write_to_screen $TOPIC $ERROR $OUTPUT
    
    # Add service account as cloudsql admin

    EXTRA=$(gcloud projects add-iam-policy-binding $PROJECT_NAME \
        --member=serviceAccount:$SERVICE_ACCOUNT \
        --role=roles/cloudsql.admin \
        --condition=None 2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error adding service account $SERVICE_ACCOUNT as cloudsql admin"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else        
        OUTPUT="Service account $SERVICE_ACCOUNT added as cloudsql admin"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
    
    # Create private database instance

    if check_database_instance $DATABASE_NAME_PRIVATE; then
        EXTRA=$(gcloud beta sql instances create $DATABASE_NAME_PRIVATE \
            --project=$PROJECT_NAME \
            --region $REGION \
            --tier db-f1-micro \
            --database-version POSTGRES_14 \
            --network=projects/$PROJECT_NAME/global/networks/$NETWORK_NAME  \
            --root-password=$ASPNETCORE_DEV_DATABASE_PASSWORD \
            --no-assign-ip \
            --enable-google-private-path 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating database instance $DATABASE_NAME_PRIVATE"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database instance $DATABASE_NAME_PRIVATE created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Database instance $DATABASE_NAME_PRIVATE already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

create_database_instance () {
    TOPIC="Create database instance"
    ERROR=-1
    OUTPUT="Creating database instance $DATABASE_INSTANCE_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Add service account as cloudsql admin

    EXTRA=$(gcloud projects add-iam-policy-binding $PROJECT_NAME \
        --member=serviceAccount:$SERVICE_ACCOUNT \
        --role=roles/cloudsql.admin \
        --condition=None 2>&1)


    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Error adding service account $SERVICE_ACCOUNT as cloudsql admin"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else        
        OUTPUT="Service account $SERVICE_ACCOUNT added as cloudsql admin"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT   

    # Create database instance
    
    if check_database_instance $DATABASE_INSTANCE_NAME ; then
        EXTRA=$(gcloud sql instances create $DATABASE_INSTANCE_NAME \
            --region $REGION \
            --tier db-f1-micro \
            --database-version POSTGRES_14 \
            --network $NETWORK_NAME \
            --root-password=$ASPNETCORE_DEV_DATABASE_PASSWORD \
            --authorized-networks=$NETWORK_NAME 2>&1)

        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating database instance $DATABASE_INSTANCE_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database instance $DATABASE_INSTANCE_NAME created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Database instance $DATABASE_INSTANCE_NAME already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

delete_database () {
    TOPIC="Delete database instance"
    ERROR=-1
    OUTPUT="Deleting database instance $DATABASE_INSTANCE_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    # Delete database instance
    # delete the public or private db based on the variable in config.sh

    if [[ $DATABASE_CHOICE == "public" ]]; then
        if ! check_database $DATABASE_INSTANCE_NAME;then
            EXTRA=$(gcloud sql databases delete $ASPNETCORE_DEV_DATABASE_NAME --instance=$DATABASE_INSTANCE_NAME --quiet 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error deleting database $ASPNETCORE_DEV_DATABASE_NAME"
                ERROR=1
                write_to_log_file $TOPIC $ERROR $OUTPUT $EXTRA
            else
                OUTPUT="Database $ASPNETCORE_DEV_DATABASE_NAME deleted"
                ERROR=0
                write_to_log_file $TOPIC $ERROR $OUTPUT
            fi
        else
            OUTPUT="Database $ASPNETCORE_DEV_DATABASE_NAME does not exist, skipping"
            ERROR=1
            write_to_log_file $TOPIC $ERROR $OUTPUT
        fi

        write_to_screen $TOPIC $ERROR $OUTPUT

        if ! check_database_instance $DATABASE_INSTANCE_NAME; then
        EXTRA=$(gcloud sql instances delete $DATABASE_INSTANCE_NAME --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting database instance $DATABASE_INSTANCE_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database instance $DATABASE_INSTANCE_NAME deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi

        else
            OUTPUT="Database instance $DATABASE_INSTANCE_NAME does not exist"
            ERROR=1
         write_log_to_file $TOPIC $ERROR $OUTPUT
        fi

        write_to_screen $TOPIC $ERROR $OUTPUT
    elif [[ $DATABASE_CHOICE == "private" ]]; then 
        if ! check_database $DATABASE_NAME_PRIVATE; then
        EXTRA=$(gcloud sql database delete $ASPNETCORE_DEV_DATABASE_NAME --instance=$DATABASE_NAME_PRIVATE --quiet 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error deleting database $ASPNETCORE_DEV_DATABASE_NAME"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            else
                OUTPUT="Database $ASPNETCORE_DEV_DATABASE_NAME deleted"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
        else
            OUTPUT="Database $ASPNETCORE_DEV_DATABASE_NAME does not exist, skipping"
            ERROR=1
            write_log_to_file c $TOPIC $ERROR $OUTPUT
        fi
        
        
        if ! check_database_instance $DATABASE_NAME_PRIVATE; then
        
            EXTRA=$(gcloud sql instances delete $DATABASE_NAME_PRIVATE --quiet 2>&1)
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Error deleting database instance $DATABASE_NAME_PRIVATE"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            else
                OUTPUT="Database instance $DATABASE_NAME_PRIVATE deleted"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
        else
            OUTPUT="Database instance $DATABASE_NAME_PRIVATE does not exist"
            ERROR=1
             write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

create_database () {
    TOPIC="Create database"
    ERROR=-1
    OUTPUT="Creating database $ASPNETCORE_DEV_DATABASE_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_database $1; then
        EXTRA=$(gcloud sql databases create $ASPNETCORE_DEV_DATABASE_NAME --instance=$1 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating database $ASPNETCORE_DEV_DATABASE_NAME"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database $ASPNETCORE_DEV_DATABASE_NAME created"
            ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Database $ASPNETCORE_DEV_DATABASE_NAME already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

choice_database_backup_option () {
    TOPIC="Choose database backup option"
    ERROR=-1
    OUTPUT="Choose database backup option: 1) create, 2) restore, 3) get backups 4) enable auto backup"
    write_to_screen $TOPIC $ERROR $OUTPUT

    # choose database backup option
    while [[ $DATABASE_BACKUP_CHOICE -le 0 || $DATABASE_BACKUP_CHOICE -gt 4 ]]; do
        read DATABASE_BACKUP_CHOICE
        write_to_screen $TOPIC $ERROR $OUTPUT
    done
    
    # call the function based on the choice
    case $DATABASE_BACKUP_CHOICE in
        1) create_database_backup;;
        2) restore_database_backup $DATABASE_ID;;
        3) get_database_backups;;
        4) enable_auto_backup;;
    esac
}

enable_auto_backup () {
    TOPIC="Enable auto backup"
    ERROR=-1
    OUTPUT="Enabling auto backup"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if [[ $DATABASE_CHOICE == "private" ]]; then
        EXTRA=$(gcloud sql instances patch $DATABASE_NAME_PRIVATE --backup-start-time 00:00  --retained-backups-count 30 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error enabling auto backup"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Auto backup enabled"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
            write_to_screen $TOPIC $ERROR $OUTPUT
        fi
    else
        EXTRA=$(gcloud sql instances patch $DATABASE_INSTANCE_NAME --backup-start-time 00:00  --retained-backups-count 30 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error enabling auto backup"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Auto backup enabled"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    fi
}

create_database_backup () {
    TOPIC="Create database backup"
    ERROR=-1
    OUTPUT="Creating database backup"
    write_to_screen $TOPIC $ERROR $OUTPUT

    if [[ $DATABASE_CHOICE == "private" ]]; then
        EXTRA=$(gcloud sql backups create --instance=$DATABASE_NAME_PRIVATE 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating database backup"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database backup for $DATABSE_NAME_PRIVATE created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else

        EXTRA=$(gcloud sql backups create --instance=$DATABASE_INSTANCE_NAMED 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating database backup"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database backup created"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

restore_database_backup () {
    TOPIC="Restore database backup"
    ERROR=-1
    OUTPUT="Restoring database backup"
    write_to_screen $TOPIC $ERROR $OUTPUT

    get_database_backups

    OUTPUT="Choose backup to restore"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read -r DATABASE_ID

    max_database_id="$(echo "${FORMATTED_BACKUPS[@]}" | wc -l)"
    if  [ $DATABASE_ID -lt 0 ] || [ $DATABASE_ID -gt $max_database_id ]; then
        OUTPUT="Invalid database id"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
        write_to_screen $TOPIC $ERROR $OUTPUT
        return
    fi
    selected_id=$(echo "${FORMATTED_BACKUPS[@]}" | grep -w "$DATABASE_ID" | rev | cut -d ' ' -f 3 | rev)
    
    if [[ $DATABASE_CHOICE == "private" ]]; then
        OUTPUT="Restoring database backup $selected_id in $DATABASE_NAME_PRIVATE"
        ERROR=-1
        write_to_screen $TOPIC $ERROR $OUTPUT
        EXTRA=$(gcloud sql backups restore $selected_id --backup-instance=$DATABASE_NAME_PRIVATE --restore-instance $DATABASE_NAME_PRIVATE 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error restoring database backup"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database backup restored"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Restoring database backup $selected_id in $DATABASE_INSTANCE_NAME"
        ERROR=-1
        write_to_screen $TOPIC $ERROR $OUTPUT
        EXTRA=$(gcloud sql backups restore $selected_id ---backup-instance=$DATABASE_INSTANCE_NAME --restore-instance $DATABASE_NAME_PRIVATE 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error restoring database backup"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Database backup restored"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
}

get_database_backups () {
    TOPIC="Get database backups"
    ERROR=-1
    OUTPUT="Getting database backups"

    write_to_screen $TOPIC $ERROR $OUTPUT 

    OUTPUT="Database choice is $DATABASE_CHOICE"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if [[ $DATABASE_CHOICE == "private" ]]; then
        EXTRA=$(gcloud sql backups list --instance $DATABASE_NAME_PRIVATE --format="csv[no-heading](id, WINDOW_START_TIME)" 2>&1)
        if [[ $EXTRA =~ ("fail") ]]; then
            OUTPUT="Error getting database backups"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        elif [[ $EXTRA =~ "Listed 0 items" ]]; then
            OUTPUT="No database backups found"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
            write_to_screen $TOPIC $ERROR $OUTPUT
            
        else
            FORMATTED_BACKUPS=$(echo "$EXTRA" | while IFS=, read -r id createTime; do
            echo "id: $id on $createTime" 2>&1
            done | nl -v 1)
            OUTPUT="Database backups found"
            write_log_to_file $TOPIC $ERROR $OUTPUT
            write_to_screen $TOPIC $ERROR $OUTPUT
            ERROR=0
            for backup in "${FORMATTED_BACKUPS[@]}"; do
                echo "$backup"
            done
        fi
    else
        EXTRA=$(gcloud sql backups list --instance=$DATABASE_INSTANCE_NAME --format="csv[no-heading](id, WINDOW_START_TIME)" 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error getting database backups"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        elif [[ -z $EXTRA ]]; then
            OUTPUT="No database backups found"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            FORMATTED_BACKUPS=$(echo "$EXTRA" | while IFS=, read -r id createTime; do
            echo "id: $id on $createTime"
            done | nl -v 1)
            OUTPUT="Database backups found"
            for backup in "${FORMATTED_BACKUPS[@]}"; do
                echo "$backup"
            done
            write_log_to_file $TOPIC $ERROR $OUTPUT
            write_to_screen $TOPIC $ERROR $OUTPUT
        fi
    fi

    # write_to_screen $TOPIC $ERROR $OUTPUT

}

check_redis_server () {
    if ! gcloud redis instances list --region $REGION 2>&1 | grep -w $REDIS_INSTANCE_NAME &> /dev/null; then
        return 0
    else
        return 1
    fi

}

create_redis_server () {
    TOPIC="Create redis server"
    ERROR=-1
    OUTPUT="Creating redis server"
    
    write_to_screen $TOPIC $ERROR $OUTPUT

    if check_redis_server; then
        EXTRA=$(gcloud redis instances create --project=$PROJECT_NAME $REDIS_INSTANCE_NAME \
        --tier=standard \
        --size=16 \
        --region=$REGION \
        --redis-version=redis_7_0 \
        --network=$NETWORK_NAME \
        --read-replicas-mode=READ_REPLICAS_ENABLED \
        --replica-count=2 \
        --connect-mode=direct-peering 2>&1)
        
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error creating redis server"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Redis server created"
            ERROR=0
            write_redis_ip_to_file
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Redis server already exists"
        write_redis_ip_to_file
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
    

    write_to_screen $TOPIC $ERROR $OUTPUT
} 

write_redis_ip_to_file () {
    TOPIC="Get redis IP"
    ERROR=-1
    OUTPUT="Getting redis IP"

    write_to_screen $TOPIC $ERROR $OUTPUT

    REDIS_IP=$(gcloud redis instances describe $REDIS_INSTANCE_NAME --region $REGION --format="value(host)" 2>&1) 

    if [[ -z $REDIS_IP ]]; then
        OUTPUT="Redis ip not found"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Redis ip found"
        REDIS="$REDIS_IP:6379"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
    
    if [[ $ERROR = 0 ]]; then
        if ! cat "$TEMP_FILE" | grep -w "$REDIS" &> /dev/null; then
        TO_WRITE="REDIS=\"$REDIS\""
        echo "$TO_WRITE" 2>&1 | cat >> $TEMP_FILE 2>&1
        OUTPUT="Writing Redis ip + port to temp file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        OUTPUT="Redis ip + port already exists in temp file"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
    fi
    
}

delete_redis_server () {
    TOPIC="Delete redis server"
    ERROR=-1
    OUTPUT="Deleting redis server"

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! check_redis_server &> /dev/null; then
        EXTRA=$(gcloud redis instances delete $REDIS_INSTANCE_NAME --region $REGION --quiet 2>&1)
        if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="Error deleting redis server"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="Redis server deleted"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
        
    else
        OUTPUT="Redis server does not exist"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi  

    write_to_screen $TOPIC $ERROR $OUTPUT
}