#!/bin/bash

source config.sh
source $LIB_DIR/logging/write-to-screen.sh
source $LIB_DIR/logging/write-log-file.sh

check_config_file () {
    ERROR=-1
    TOPIC="Config file"
    OUTPUT="Checking if config file exists"
    write_to_screen $TOPIC $OUTPUT $ERROR

    if [ -f config.sh ]; then
        ERROR=0
        OUTPUT="Config file exists"
        write_to_screen $TOPIC $OUTPUT $ERROR
    else
        OUTPUT="Config file does not exist"
        ERROR=-1
        write_to_screen $TOPIC $OUTPUT $ERROR
        OUTPUT="Want to copy the default config file? (y/n)"
        write_to_screen $TOPIC $OUTPUT $ERROR
        read COPY_CONFIG
        if [ $COPY_CONFIG == "y" ]; then
            cp config.sh.template config.sh
            OUTPUT="Config file copied"
            ERROR=0
        else
            OUTPUT="Config file not copied"
            ERROR=1
        fi
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    write_log_to_file $TOPIC $ERROR $OUTPUT

}

prompt_edit_config_file () {
    TOPIC="Edit config file"
    ERROR=-1
    OUTPUT="Want to edit the config file? (y/n)"
    write_to_screen $TOPIC $OUTPUT $ERROR
    read EDIT_CONFIG

    if [ $EDIT_CONFIG == "y" ]; then
        OUTPUT="Which editor you want to use? 1. Nano 2. Vim 3. VSCode 4. Sublime 5. Notepad 6. Gedit 7. TextEdit"
        ERROR=-2
        write_to_screen $TOPIC $OUTPUT $ERROR
        read EDITOR_CHOICE
        if [ $EDITOR_CHOICE == "1" ]; then
            nano config.sh
        elif [ $EDITOR_CHOICE == "2" ]; then
            vim config.sh
        elif [ $EDITOR_CHOICE == "3" ]; then
            code config.sh
        elif [ $EDITOR_CHOICE == "4" ]; then
            subl config.sh
        elif [ $EDITOR_CHOICE == "5" ]; then
            notepad config.sh
        elif [ $EDITOR_CHOICE == "6" ]; then
            gedit config.sh
        elif [ $EDITOR_CHOICE == "7" ]; then
            open -a TextEdit config.sh
        fi
    else
        OUTPUT="Config file not edited"
        ERROR=1
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    write_log_to_file $TOPIC $ERROR $OUTPUT



}

show_config_values () {
    while IFS= read -r line; do
        echo "$line"
    done < config.sh
}

check_gcloud_installed () {
    ERROR=-1
    TOPIC="GCloud SDK installation"
    OUTPUT="Checking if gcloud is installed"
    write_to_screen $TOPIC $OUTPUT $ERROR
    
    if ! command -v gcloud > /dev/null; then
        ERROR=1
        OUTPUT="GCloud SDK not installed"
    else 
        ERROR=0
        OUTPUT="GCloud SDK installed"
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    write_log_to_file $TOPIC $ERROR $OUTPUT
}

check_python_installed () {
    ERROR=-1
    TOPIC="Python installation"
    OUTPUT="Checking if python is installed"
    write_to_screen $TOPIC $OUTPUT $ERROR

    if ! command -v python3 > /dev/null; then
        ERROR=1
        OUTPUT="Python not installed"
    else
        ERROR=0
        OUTPUT="Python installed"
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    write_log_to_file $TOPIC $ERROR $OUTPUT
}

check_jq_installed () {
    ERROR=-1
    TOPIC="JQ installation"
    OUTPUT="Checking if jq is installed"
    write_to_screen $TOPIC $OUTPUT $ERROR

    if ! command -v jq > /dev/null; then
        ERROR=1
        OUTPUT="JQ not installed"
    else
        ERROR=0
        OUTPUT="JQ installed"
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    write_log_to_file $TOPIC $ERROR $OUTPUT
}

check_figlet_installed () {
    ERROR=-1
    TOPIC="Figlet installation"
    OUTPUT="Checking if figlet is installed"
    write_to_screen $TOPIC $OUTPUT $ERROR

    if ! command -v figlet > /dev/null; then
        ERROR=1
        OUTPUT="Figlet not installed"
        write_log_to_file $TOPIC $ERROR $OUTPUT
        OUTPUT="Want to install figlet? (y/n)"
        write_to_screen $TOPIC $OUTPUT $ERROR
        ERROR=-2
        read INSTALL_FIGLET
        if [ $INSTALL_FIGLET == "y" ]; then
            sudo apt-get install figlet lolcat
        else
            ERROR=0
            OUTPUT="Figlet not installed"
        fi
    else
        ERROR=0
        OUTPUT="Figlet installed"
    fi

    write_to_screen $TOPIC $ERROR $OUTPUT
    write_log_to_file $TOPIC $ERROR $OUTPUT
}