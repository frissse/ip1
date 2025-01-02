#!/usr/bin/env bash



source variables.sh

# # # enable gcloud secret manager
# # gcloud services enable secretmanager.googleapis.com

echo "cloning repo $gitrepo"

if [ "$1" = "yes" ]; then
    if [ -d ./Phygital ]; then
        rm -rf ./Phygital
        mkdir ./$foldername
    fi
    git clone $gitrepo $foldername
else
    echo "working with current git pull version"
fi


if [ $? -ne 0 ]; then
    echo "cloning failed"
    exit 1
fi

echo "cloning complete"
echo "copying necessary files"

# sudo chmod -R 777 $foldername

cp app.yaml ./$foldername/
cp secrets.yaml ./$foldername/
cp Dockerfile ./$foldername/

cd $foldername

echo "start deploying to app engine"

# docker build --no-cache -t dotnettest .

gcloud app deploy

