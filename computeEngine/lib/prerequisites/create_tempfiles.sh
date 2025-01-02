#!/bin/bash

source config.sh

temp_file=""

delete_temp_file_from_config () {
    TOPIC="Temp file"
    OUTPUT="Deleting temp file from config.sh"
    ERROR=-1

    sed -i '' '/TEMP_FILE/d' config.sh

    write_to_screen $TOPIC $OUTPUT
    write_log_to_file $TOPIC $OUTPUT
}

create_temp_file () {
    TOPIC="Temp file"
    OUTPUT="Creatting tempfile"
    
    write_to_screen $TOPIC $OUTPUT

    temp_file=$(mktemp -t temp-envvar.sh)

    OUTPUT="Temp file created: $temp_file"

    write_to_screen $TOPIC $OUTPUT

cat <<EOF > $temp_file
#!/bin/bash
export DOTNET_CLI_HOME=/root/
PROJECT_NAME="$PROJECT_NAME"
GIT_DIRECTORY="pm"
GIT_TOKEN="$GIT_TOKEN"
GIT_URL="https://oauth2:$GIT_TOKEN@gitlab.com/kdg-ti/integratieproject-1/202324/8_mf_i/dotnet.git"
BRANCH_NAME="$BRANCH_NAME"
BUCKET_NAME="$PROJECT_NAME-bucket"
ASPNETCORE_ENVIRONMENT="Production"
ASPNETCORE_DEV_DATABASE_PASSWORD="$ASPNETCORE_DEV_DATABASE_PASSWORD"
ASPNETCORE_DEV_DATABASE_NAME="$ASPNETCORE_DEV_DATABASE_NAME"
ASPNETCORE_DEV_DATABASE_USER="postgres"
ASPNETCORE_DEV_DATABASE_PORT="5432"
ASPNETCORE_CONTENTROOT=/home/phygital/pm/UI-MVC/
CONTENT_SAFETY_ENDPOINT=$CONTENT_SAFETY_ENDPOINT
CONTENT_SAFETY_KEY=$CONTENT_SAFETY_KEY
HF_ACCESS_TOKEN=$HF_ACCESS_TOKEN
EOF

    write_to_screen $TOPIC $OUTPUT
    write_log_to_file $TOPIC $OUTPUT 
}

write_temp_file_to_config () {
    TOPIC="Temp file"
    OUTPUT="Writing temp file to config.sh"

    TO_WRITE="TEMP_FILE=$temp_file"
    echo "$TO_WRITE" 2>&1 | cat >> config.sh 2>&1

    write_to_screen $TOPIC $OUTPUT
    write_log_to_file $TOPIC $OUTPUT
}

show_content_temp_file () {
    TOPIC="Temp file"
    OUTPUT="Showing content of temp file"

    write_to_screen $TOPIC $OUTPUT

    cat $TEMP_FILE

    OUTPUT="is this correct? y/n"
    ERROR=-2
    write_to_screen $TOPIC $ERROR $OUTPUT
    read INPUT 

    if [[ $INPUT == "y" ]]; then
        OUTPUT="Okay, moving on"
        ERROR=0
    else
        OUTPUT="Okay, stopping script"
        ERROR=1
        exit 1
    fi

    write_to_screen $TOPIC $OUTPUT
    write_log_to_file $TOPIC $OUTPUT
}