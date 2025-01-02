#TODO: check if gcloud is installed
#TODO: colors in script
#TODO: check if pbject already exist
#TODO: eigen network opzetten en alles hier binnen draaien

# gcloud projects delete $PROJECT_NAME 

# create profile

# gcloud projects create $PROJECT_NAME  --name="$PROJECT_NAME"

# link billing account 

# gcloud billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT_ID

# enable compute engine API

# gcloud services enable compute.googleapis.com --project=$PROJECT_NAME

# set the newly made project as the project to use

# gcloud config set project $PROJECT_NAME

# SERVICE_ACCOUNT=$(gcloud iam service-accounts list --project="$PROJECT_NAME" | grep "Compute Engine" | cut -d ' ' -f 7)

# if ! cat env-var.txt | grep -w $ASPNETCORE_DEV_DATABASE_HOST; then
#     echo "SERVICE_ACCOUNT=\"$SERVICE_ACCOUNT\"" >> env-var.txt
# fi
# gcloud config set compute/zone $ZONE

# # check if bucket exist

# # if not exist create bucket

# gsutil mb gs://media-bucket

# #create instance templates for test & production

# check here if database exist or not

# if ! gcloud sql instances list | grep phygital-database &> /dev/null; then
#     gcloud sql instances create phygital-database \
#     --region $REGION \
#     --tier db-f1-micro \
#     --database-version POSTGRES_14 \
#     --root-password=$ASPNETCORE_DEV_DATABASE_PASSWORD \
#     --authorized-networks="0.0.0.0/0"

# else
#     echo "database already exists, skipping"
# fi

# if ! gcloud sql databases list  --instance phygital-database | grep $ASPNETCORE_DEV_DATABASE_NAME &> /dev/null; then
#     gcloud sql databases create $ASPNETCORE_DEV_DATABASE_NAME --instance="phygital-database"
# fi

# echo "getting IP from database to be used in startup script" 

# ASPNETCORE_DEV_DATABASE_HOST=$(gcloud sql instances describe phygital-database --format="value(ipAddresses.ipAddress)" | cut -d ';' -f 1)

# if [ -n "$ASPNETCORE_DEV_DATABASE_HOST" ]; then
#     echo "export ASPNETCORE_DEV_DATABASE_HOST=\"$ASPNETCORE_DEV_DATABASE_HOST\"" >> env-var.txt
# else
#     echo "trying again"
#     ASPNETCORE_DEV_DATABASE_HOST=$(gcloud sql instances describe phygital-database --format="value(ipAddresses.ipAddress)" | cut -d ';' -f 1)
# fi

# if ! cat env-var.txt | grep -w $ASPNETCORE_DEV_DATABASE_HOST; then
#     echo "ASPNETCORE_DEV_DATABASE_HOST=\"$ASPNETCORE_DEV_DATABASE_HOST\"" >> env-var.txt
# fi

# gcloud secrets create phygital-secrets --replication-policy="automatic" --data-file=env-var.txt

# gcloud secrets add-iam-policy-binding phygital-secrets \
#     --member=serviceAccount:$SERVICE_ACCOUNT \
#     --role="roles/secretmanager.admin"

# if ! gcloud compute instance-templates list | grep $TEMPLATE_NAME &> /dev/null; then
#     gcloud compute instance-templates create $TEMPLATE_NAME \
#     --project=$PROJECT_NAME \
#     --scopes "https://www.googleapis.com/auth/cloud-platform" \
#     --machine-type=$MACHINE_TYPE \
#     --service-account=$SERVICE_ACCOUNT \
#     --create-disk=auto-delete=yes,boot=yes,device-name=physical-instance-test,image=$IMAGE,mode=rw,size=10,type=pd-balanced \
#     --metadata-from-file startup-script=./startup-script.sh \
#     --tags dotnet-instance,http-server,https-server
# else
#     echo "template already exists, skipping"
# fi

# gcloud compute instances create $INSTANCE_NAME \
#     --source-instance-template $TEMPLATE_NAME \
#     --zone $ZONE

# gcloud compute firewall-rules create $FW_ALLOW_PORT_5000 \
#   --allow tcp:5000 \          
#   --source-ranges 0.0.0.0/0 \
#   --target-tags dotnet-instance

# create load balancer

# gcloud compute ssl-certificates create $SSL_CERTIFICATE --domains=$DOMAIN_NAME --global

# instance group aanmaken

# gcloud compute instance-groups managed create $INSTANCE_GROUP --zone=$ZONE --template=$TEMPLATE_NAME --size=$INSTANCE_GROUP_SIZE

# gcloud compute instance-groups managed set-autoscaling $INSTANCE_GROUP --max-num-replicas $INSTANCE_GROUP_MAX_REPLICAS \
#   --target-cpu-utilization $INSTANCE_GROUP_TARGET_CPU_UTIL \

# gcloud compute instance-groups set-named-ports $INSTANCE_GROUP --named-ports=http:5000

# gcloud compute firewall-rules create $FW_HEALTH_CHECK \
#     --network=default \
#     --action=allow \
#     --direction=ingress \
#     --source-ranges=130.211.0.0/22,35.191.0.0/16 \
#     --target-tags=allow-health-check \
#     --rules=tcp:80

# gcloud compute addresses create $LB_STATIC_IP \
#     --ip-version=IPV4 \
#     --network-tier=PREMIUM \
#     --global

# # # create health check

# gcloud compute health-checks create http $HEALTH_CHECK \
#      --port 80 \
#      --global \
#      --enable-logging \
#      --check-interval=$HEALTH_CHECK_INTERVAL \
#      --timeout=$HEALTH_CHECK_TIMEOUT \

# gcloud compute health-checks create https $HEALTH_CHECK_HTTPS \
#      --port 443 \
#      --global \
#      --enable-logging \
#      --check-interval=$HEALTH_CHECK_INTERVAL \
#      --timeout=$HEALTH_CHECK_TIMEOUT \

# gcloud compute backend-services create $LB_BACKEND \
#     --load-balancing-scheme=EXTERNAL \
#     --protocol=HTTP \
#     --port-name=http \
#     --health-checks=$HEALTH_CHECK \
#     --global

# gcloud compute backend-services add-backend $LB_BACKEND \
#     --instance-group=$INSTANCE_GROUP \
#     --instance-group-zone=$ZONE \
#     --global

# gcloud compute url-maps create $URL_MAP \
#   --default-service $LB_BACKEND

# gcloud compute target-https-proxies create $PROXY \
#     --url-map=$URL_MAP \
#     --ssl-certificates=$SSL_CERTIFICATE

# gcloud compute ssl-policies create phygital-ssl-policy \
#     --profile MODERN \
#     --min-tls-version 1.0

# gcloud compute target-http-proxies create $PROXY --url-map $URL_MAP

# gcloud compute target-https-proxies update $PROXY_HTTPS --ssl-policy phygital-ssl-policy

# gcloud compute forwarding-rules create $FORWARDING_RULE_HTTPS \
#   --load-balancing-scheme=EXTERNAL \
#   --network-tier=PREMIUM \
#   --address=phygital-ipv4-1 \
#   --global \
#   --target-https-proxy=$PROXY_HTTPS \
#   --ports=443

# gcloud compute forwarding-rules create $FORWARDING_RULE_HTTP \
#     --load-balancing-scheme=EXTERNAL \
#     --address=$LB_STATIC_IP \
#     --global \
#     --target-http-proxy=$PROXY \
#     --ports=80

# INSTANCE_NAME=$(gcloud compute instance-groups list-instances phygital-1 --zone $ZONE | cut -d " " -f 1 | head -n 1)

# # edit settings for load balancer

# MAX_TRIES=10 
# attempt=0

# while [[ $attempt -lt $MAX_TRIES ]]; do
#     if gcloud compute ssh --quiet --zone "$ZONE" "$INSTANCE_NAME" --command="echo hello" &> /dev/null; then
#        gcloud compute scp --recurse /Users/alex/deployment/computeEngine/app/ $INSTANCE_NAME:
#        gcloud compute ssh --project boxwood-weaver-415718 --zone europe-central2-c $INSTANCE_NAME --command="cd app/; dotnet PM.UI.Web.MVC.dll"
#        break
#     fi

#     echo "SSH is not available on $INSTANCE_NAME (attempt $((attempt + 1)) of $MAX_TRIES)"
#     sleep 5  # Wait 5 seconds before retrying (adjust as needed)
#     attempt=$((attempt + 1))
# done