#!/bin/bash

source source_scripts.sh

check_gcloud_installed
check_python_installed
check_jq_installed
check_figlet_installed

figlet -f slant "Phygital Deployment" | lolcat

OUTPUT="Starting deployment script..."
ERROR=-1
TOPIC="Starting phygital GCloud Management script"
write_to_screen $TOPIC $ERROR $OUTPUT

check_config_file
prompt_edit_config_file
get_current_project

delete_temp_file_from_config
create_temp_file
write_temp_file_to_config

while true; do
  TOPIC="Choice script type"
  OUTPUT="Choice an option: 1) deploy an (part of an) application 2) delete a (part of an) application 3) update code or specs 4) settings & backups 5) exit "
  ERROR=-2
  write_to_screen $TOPIC $ERROR $OUTPUT
  read choice

  # Check the user input and execute corresponding script
  if [[ "$choice" == "1" ]]; then
    OUTPUT="Running deploy script..."
    ERROR=-1
    write_to_screen $TOPIC $ERROR $OUTPUT
    sh ./deploy.sh  
    break  # Exit the loop if a valid choice is made
  elif [[ "$choice" == "2" ]]; then
    OUTPUT="Running delete script..."
    ERROR=-1
    write_to_screen $TOPIC $ERROR $OUTPUT
    sh ./delete.sh  
    break  # Exit the loop if a valid choice is made
  elif [[ "$choice" == "3" ]]; then
    OUTPUT="Running upgrade script"
    ERROR=-1
    write_to_screen $TOPIC $ERROR $OUTPUT
    bash ./upgrade.sh
    break  # Exit the loop if a valid choice is made
  elif [[ "$choice" == "4" ]]; then
    OUTPUT="Running settings & backups script"
    ERROR=-1
    write_to_screen $TOPIC $ERROR $OUTPUT
    bash ./settings.sh
    break  # Exit the loop if a valid choice is made
  elif [[ "$choice" == "5" ]]; then
    OUTPUT="Exiting script..."
    ERROR=-1
    write_to_screen $TOPIC $ERROR $OUTPUT
    break  # Exit the loop if a valid choice is made
  else
    echo "Invalid choice. Please try again."
  fi
done
