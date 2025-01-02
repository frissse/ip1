#!/usr/bin/bash

source config.sh
source $LIB_DIR/logging/write-log-file.sh
source $LIB_DIR/logging/write-to-screen.sh

PROJECTS=""
SELECTION=""

get_current_project () {
    TOPIC="Current project"
    ERROR=-1
    OUTPUT="Getting current project"
    write_to_screen $TOPIC $ERROR $OUTPUT

    PROJECT=$(gcloud config get-value project 2>&1)

    if [ -n "$PROJECT" ]; then
        ERROR=0
        OUTPUT="Current project found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        OUTPUT="Current project is $PROJECT"
        write_to_screen $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Current project not found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi


}

get_projects () {
    TOPIC="Project"
    ERROR=-1
    OUTPUT="Getting projects in Account $USER_NAME"

    write_to_screen $TOPIC $ERROR $OUTPUT
    
    PROJECTS=$(gcloud projects list --sort-by=projectId --format="csv[no-heading](PROJECT_ID, NAME)")
    PROJECTS=$(echo "$PROJECTS" | while IFS=, read -r PROJECT_ID NAME; do
            echo "id: $PROJECT_ID with name: $NAME"
            done | nl -v 1)

    if [ -n "$PROJECTS" ]; then
        ERROR=0
        OUTPUT="Projects found"
        write_to_screen $TOPIC $ERROR $OUTPUT
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Projects not found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi
}

choose_project () {
    TOPIC="Choose project"
    ERROR=-1
    OUTPUT="Choose project from the list"
    write_to_screen $TOPIC $ERROR $OUTPUT

    get_projects

    if [ -n "$PROJECTS" ]; then
        ERROR=0
        OUTPUT="Projects found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        
        OUTPUT="Choose project id from the list or enter [n]ew to create a new project:"
        write_to_screen $TOPIC $ERROR $OUTPUT
        echo "$PROJECTS"
        read PROJECT
        if [ "$PROJECT" == "n" ]; then
            create_project
        else
            PROJECT=$(echo "$PROJECTS" | grep -w "$PROJECT")
            SELECTION=$(echo "${PROJECT// /,}" | rev | cut -d ',' -f 4 | rev)
            OUTPUT="Selected project $SELECTION, want to make this the default project?"
            write_to_screen $TOPIC $ERROR $OUTPUT
            read -p "Enter y/n: " CHOICE
            if [ "$CHOICE" == "y" ]; then
                FILE="config.sh"
                sed -i'' "s/^PROJECT_NAME=.*/PROJECT_NAME=\"$SELECTION\"/g" "$FILE"
                rm -f config.sh-e
                set_default_profile
                check_billing_account
                check_apis
                OUTPUT="Project $SELECTION selected, and written to file $FILE"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT
            else
                ERROR=1
                OUTPUT="Project not selected"
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
        fi
        
    else
        ERROR=1
        OUTPUT="Projects not found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

check_billing_account () {
    TOPIC="Check billing account"
    ERROR=-1
    OUTPUT="Checking billing account"
    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud beta billing accounts list --format="csv[no-heading]($BILLING_ACCOUNT_ID)" | head -n 1)
    if [ -z "$EXTRA" ]; then
        OUTPUT="Billing account $BILLING_ACCOUNT_ID not found"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        OUTPUT="No billing account found, want to link $BILLING_ACCOUNT_ID to project $PROJECT_NAME? [y/n]"
        ERROR=-2
        write_to_screen $TOPIC $ERROR $OUTPUT
        read CHOICE
        if [ "$CHOICE" == "y" ]; then
            link_billing_account
        else 
            OUTPUT="Billing account not linked"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Billing account $BILLING_ACCOUNT_ID found"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi
}

check_apis () {
    TOPIC="Check APIs"
    ERROR=-1
    OUTPUT="Checking APIs"
    write_to_screen $TOPIC $ERROR $OUTPUT

    APIS=(
    "compute.googleapis.com"
    "sqladmin.googleapis.com"
    "secretmanager.googleapis.com"
    "dns.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "servicenetworking.googleapis.com"
    "certificatemanager.googlqeapis.com"
    "osconfig.googleapis.com"
    "redis.googleapis.com"
    )

    for api in "${APIS[@]}"; do
        EXTRA=$(gcloud services list --project=$PROJECT_NAME | grep $api)
        if [ -n "$EXTRA" ]; then
            OUTPUT="API $api enabled"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="API $api not enabled"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
            gcloud services enable $api --project=$PROJECT_NAME 2>&1
        fi
    done


}

set_default_profile () {
    TOPIC="Set default profile"
    ERROR=-1
    OUTPUT="Setting default profile to $PROJECT_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT
    
    get_projects

    source config.sh
    OUTPUT="Choose project id from the list or enter [n]ew to create a new project:"
    write_to_screen $TOPIC $ERROR $OUTPUT
    echo "$PROJECTS"
    read PROJECT
    if [ "$PROJECT" == "n" ]; then
        create_project
    else
        PROJECT=$(echo "$PROJECTS" | grep -w "$PROJECT")
        SELECTION=$(echo "${PROJECT// /,}" | rev | cut -d ',' -f 4 | rev)
        OUTPUT="Selected project $SELECTION, want to make this the default project? [y/n]"
        write_to_screen $TOPIC $ERROR $OUTPUT
        read CHOICE
        if [ "$CHOICE" == "y" ]; then
            FILE="config.sh"
            sed -i'' -e "s/^PROJECT_NAME=.*/PROJECT_NAME=\"$SELECTION\"/g" "$FILE"
            rm -f config.sh-e
            EXTRA=$(gcloud config set project "$SELECTION" 2>&1)

            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Default profile not set to $PROJECT_NAME"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            else
                OUTPUT="Default profile set to $PROJECT_NAME"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi
            OUTPUT="Project $SELECTION selected, and written to file $FILE"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            ERROR=1
            OUTPUT="Project not selected"
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    fi

    

    write_to_screen $TOPIC $ERROR $OUTPUT
}

set_default_compute_region () {
    TOPIC="Set default compute region"
    ERROR=-1
    OUTPUT="Setting default compute region to $COMPUTE_REGION"
    write_to_screen $TOPIC $ERROR $OUTPUT

    OUTPUT="Enter the default compute region:"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read COMPUTE_REGION

    EXTRA=$(gcloud config set compute/region "$COMPUTE_REGION" 2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="Default compute region not set to $COMPUTE_REGION"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Default compute region set to $COMPUTE_REGION"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

get_user () {
    ERROR=-1
    TOPIC="User"
    OUTPUT="Getting user"
    write_to_screen $TOPIC $OUTPUT $ERROR
    USER=$(gcloud config get account 2>&1)
    
    if [ -n "$USER" ]; then   
        ERROR=0
        OUTPUT="User found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        if ! cat $TEMP_FILE | grep "USER_NAME" > /dev/null; then
            TO_WRITE="USER_NAME=\"$USER\"" 
            echo "$TO_WRITE" | tee -a "$TEMP_FILE" > /dev/null
            OUTPUT="User $USER written to temp file"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            ERROR=1
            OUTPUT="User already exists in temp file"
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        ERROR=1
        OUTPUT="User not found"
    fi

    write_to_screen $TOPIC $ERROR "$OUTPUT"

    
    if ! cat config.sh | grep -w "USER_NAME" > /dev/null; then
        TO_WRITE="USER_NAME=\"$USER\""
        echo "$TO_WRITE" | tee -a config.sh > /dev/null
        OUTPUT="User $USER written to config.sh"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT

    else
        ERROR=1
        OUTPUT="User already exists in config.sh"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR
}

get_service_account () {
    TOPIC="Service account"
    SERVICE_ACCOUNT=$(gcloud iam service-accounts list --project="$PROJECT_NAME" | grep "Compute Engine" | cut -d ' ' -f 7)

    if [ -n "$SERVICE_ACCOUNT" ]; then
        ERROR=0
        OUTPUT="Service account found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Service account not found"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! cat $TEMP_FILE | grep -w "SERVICE_ACCOUNT" > /dev/null; then
        TO_WRITE="SERVICE_ACCOUNT=\"$SERVICE_ACCOUNT\""
        echo "$TO_WRITE" | tee -a $TEMP_FILE > /dev/null
        OUTPUT="Writing service account to temp file"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Service account already exists in temp file"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

    if ! cat config.sh | grep -w "SERVICE_ACCOUNT" > /dev/null; then
        TO_WRITE="SERVICE_ACCOUNT=\"$SERVICE_ACCOUNT\""
        echo "$TO_WRITE" 2>&1| tee -a config.sh > /dev/null
        OUTPUT="Writing service account to config.sh"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT
    else
        ERROR=1
        OUTPUT="Service account already exists in config.sh"
        write_log_to_file $TOPIC $ERROR $OUTPUT
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    
}

link_billing_account () {
    TOPIC="Link billing account"
    ERROR=-1
    OUTPUT="Linking billing account $BILLING_ACCOUNT_ID to project $PROJECT_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT_ID 2>&1)
    if [ $? -eq 0 ]; then
        OUTPUT="Billing account linked"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Billing account not linked"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi
    
    write_to_screen $TOPIC $ERROR $OUTPUT
}

unlink_billing_account () {
    TOPIC="Unlink billing account"
    ERROR=-1
    OUTPUT="Unlinking billing account $BILLING_ACCOUNT_ID from project $PROJECT_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    EXTRA=$(gcloud beta billing projects unlink $PROJECT_NAME 2>&1)
    if [ $? -eq 0 ]; then
        OUTPUT="Billing account unlinked"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="Billing account not unlinked"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT

}

check_project () {
    if ! gcloud projects list --sort-by=projectId | grep $PROJECT_NAME > /dev/null; then
        return 0;
    else
        return 1
    fi
}

delete_project () {
    TOPIC="Delete project"
    ERROR=-1
    OUTPUT="Deleting project $PROJECT_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT

    #check if project exists, then delete
    if ! check_project; then
        OUTPUT="Project $PROJECT_NAME does not exist"
        ERROR=1
        write_to_log_file $TOPIC $ERROR $OUTPUT
    else
        gcloud projects delete $PROJECT_NAME --quiet > /dev/null
        OUTPUT="Project $PROJECT_NAME deleted"
        ERROR=0
        write_to_log_file $TOPIC $ERROR $OUTPUT
    fi  

    write_to_screen $TOPIC $ERROR $OUTPUT  
}

create_project () {
    TOPIC="Create project"
    ERROR=-1
    OUTPUT="Creating project $PROJECT_NAME"
    write_to_screen $TOPIC $ERROR $OUTPUT
    
    if check_project; then
        OUTPUT="Will create new project with name $PROJECT_NAME"
        ERROR=0
        write_to_screen $TOPIC $ERROR $OUTPUT
        OUTPUT="Are you sure you want to create project $PROJECT_NAME? [y/n]"
        ERROR=-2
        write_to_screen $TOPIC $ERROR $OUTPUT
        read  CHOICE
        if [ "$CHOICE" == "y" ]; then
            EXTRA=$(gcloud projects create $PROJECT_NAME  --name="$PROJECT_NAME" 2>&1 )
            if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                OUTPUT="Project $PROJECT_NAME not created"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
            else 
                OUTPUT="Project $PROJECT_NAME created"
                ERROR=0
                write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
                write_to_screen $TOPIC $ERROR $OUTPUT
                set_default_profile
                link_billing_account
                enable_apis
            fi
        else
            OUTPUT="Project $PROJECT_NAME not created"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
        fi
    else
        OUTPUT="Project $PROJECT_NAME already exists"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT 

    EXTRA=$(gcloud projects add-iam-policy-binding $PROJECT_NAME --member="user:$USER_NAME" --role='roles/owner' 2>&1)

    if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
        OUTPUT="User $USER_NAME not added as owner"
        ERROR=1
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    else
        OUTPUT="User $USER_NAME added as owner"
        ERROR=0
        write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT 
}

check_apis () {
    TOPIC="Check if APIs enabled on $PROJECT_NAME"
    ERROR=-1
    OUTPUT="Checking APIs"
    write_to_screen $TOPIC $ERROR $OUTPUT

    APIS=(
        "compute.googleapis.com"
        "sqladmin.googleapis.com"
        "secretmanager.googleapis.com"
        "dns.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "servicenetworking.googleapis.com"
        "certificatemanager.googlqeapis.com"
        "osconfig.googleapis.com"
        "redis.googleapis.com"
    )

    for api in "${APIS[@]}"; do
        EXTRA=$(gcloud services list --project=$PROJECT_NAME | grep $api)
        if [ -n "$EXTRA" ]; then
            OUTPUT="API $api enabled"
            ERROR=0
            write_log_to_file $TOPIC $ERROR $OUTPUT
        else
            OUTPUT="API $api not enabled"
            ERROR=1
            write_log_to_file $TOPIC $ERROR $OUTPUT
            OUTPUT="Want to enable $api? [y/n]"
            ERROR=-2
            write_to_screen $TOPIC $ERROR $OUTPUT
            read CHOICE
            if [ "$CHOICE" == "y" ]; then
                TOPIC="Enabling APIs"
                OUTPUT="Enabling API $api"
                ERROR=-1
                write_to_screen $TOPIC $ERROR $OUTPUT
                EXTRA=$(gcloud services enable $api --project=$PROJECT_NAME 2>&1)
                if [[ $EXTRA =~ ("ERROR"|"fail") ]]; then
                    OUTPUT="API $api not enabled"
                    ERROR=1
                    write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
                else
                    OUTPUT="API $api enabled"
                    ERROR=0
                    write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
                fi
            else 
                OUTPUT="API $api not enabled"
                ERROR=1
                write_log_to_file $TOPIC $ERROR $OUTPUT
            fi
        fi
    done

}

enable_apis () {
    TOPIC="Enable APIs"
    ERROR=-1
    OUTPUT="Enabling APIs"
    write_to_screen $TOPIC $ERROR $OUTPUT

    APIS=(
    "compute.googleapis.com"
    "sqladmin.googleapis.com"
    "secretmanager.googleapis.com"
    "dns.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "servicenetworking.googleapis.com"
    "certificatemanager.googlqeapis.com"
    "osconfig.googleapis.com"
    "redis.googleapis.com"
    )

    #loop through the apis and enable them
    for api in "${APIS[@]}"; do
        EXTRA=$(gcloud services enable $api --project=$PROJECT_NAME 2>&1)
        if [[  $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="API $api not enabled"
            ERROR=1
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="API $api enabled"
            ERROR=0
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    done

    write_to_screen $TOPIC $ERROR $OUTPUT
}

disable_apis () {
    TOPIC="Disable APIs"
    ERROR=-1
    OUTPUT="Disabling APIs"
    write_to_screen $TOPIC $ERROR $OUTPUT

    APIS=(
    "compute.googleapis.com"
    "sqladmin.googleapis.com"
    "secretmanager.googleapis.com"
    "dns.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "servicenetworking.googleapis.com"
    "certificatemanager.googlqeapis.com"
    "osconfig.googleapis.com"
    "redis.googleapis.com")

    #loop through the apis and disable them
    for api in "${APIS[@]}"; do
        EXTRA=$(gcloud services disable $api --force --project=$PROJECT_NAME 2>&1)
        if [[  $EXTRA =~ ("ERROR"|"fail") ]]; then
            OUTPUT="API $api not disabled"
            ERROR=1
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        else
            OUTPUT="API $api disabled"
            ERROR=0
            write_to_screen $TOPIC $ERROR $OUTPUT
            write_log_to_file $TOPIC $ERROR $OUTPUT $EXTRA
        fi
    done
}