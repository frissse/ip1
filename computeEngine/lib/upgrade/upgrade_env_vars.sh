#!/bin/bash]

systemctl stop phygital.service
rm /etc/envvar.sh

gcloud secrets versions access latest --secret="phygital-secrets" >> /etc/envvar.sh

source /etc/envvar.sh

systemctl restart phygital.service