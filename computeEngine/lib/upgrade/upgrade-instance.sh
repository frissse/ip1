#!/bin/bash

systemctl stop phygital.service
rm /etc/envvar.sh



gcloud secrets versions access latest --secret="phygital-secrets" >> secrets.sh
gcloud secrets versions access latest --secret="phygital-secrets" >> /etc/envvar.sh

source secrets.sh

echo $BRANCH_NAME

# delete the content of the git folder + de build folder
rm -rf /var/www/phygital/
rm -rf /home/phygital/$GIT_DIRECTORY
rm -rf /home/phygital/app

mkdir /home/phygital/$GIT_DIRECTORY
mkdir /home/phygital/app
mkdir /var/www/phygital
chown -R phygital:phygital /var/www/phygital

# # pull the new content
git clone -b $BRANCH_NAME $GIT_URL /home/phygital/$GIT_DIRECTORY
echo "HF_ACCESS_TOKEN=$HF_ACCESS_TOKEN" > /home/phygital/$GIT_DIRECTORY/UI-MVC/ClientApp/.env

# # run nmp install & nmp build
cd /home/phygital/$GIT_DIRECTORY/UI-MVC/ClientApp
npm install
npm run build

# # run dotnet publish
dotnet publish "/home/phygital/pm/UI-MVC/UI-MVC.csproj" -c Release -o /home/phygital/app/

cp -r /home/phygital/app /var/www/phygital
chown -R phygital:phygital /var/www/phygital


# # restart the system unit
systemctl restart phygital.service

