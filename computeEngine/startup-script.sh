#!/bin/bash

whoami
# TODO: check if service exists 
if id "phygital" >/dev/null 2>&1; then
    sudo deluser phygital
    sudo rm -rf /home/phygital
fi

sudo useradd -s /bin/bash -md /home/phygital phygital
sudo usermod --password phygital phygital
sudo usermod -aG sudo phygital

gcloud secrets versions access latest --secret="phygital-secrets" > secrets.sh
cat secrets.txt

chmod +x secrets.sh

source secrets.sh

echo $GIT_DIRECTORY

echo "user created"
apt-get update 
apt-get upgrade -y
apt install curl wget git

curl https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb  -O
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

apt update

apt-get install -y dotnet-sdk-8.0 

echo "dotnet installed"

apt-get install -y nodejs npm redis-server

echo "nodejs installed" 

# check if $GIT_DIRECTORY already exists, if so verwijderen en opnieuw aanmaken

if [ -d "/home/phygital/$GIT_DIRECTORY" ] ; then
    rm -rf /home/phygital/$GIT_DIRECTORY
    mkdir /home/phygital/$GIT_DIRECTORY
fi

git clone -b $BRANCH_NAME $GIT_URL /home/phygital/$GIT_DIRECTORY
echo "HF_ACCESS_TOKEN=$HF_ACCESS_TOKEN" > /home/phygital/$GIT_DIRECTORY/UI-MVC/ClientApp/.env

cd /home/phygital/

mkdir /home/phygital/app

rm -rf /home/phygital/app/* 

cd /home/phygital/$GIT_DIRECTORY/UI-MVC/ClientApp 

echo "$(pwd)" 

npm install
npm run build 

cd /home/phygital/$GIT_DIRECTORY

dotnet publish "/home/phygital/pm/UI-MVC/UI-MVC.csproj" -c Release -o /home/phygital/app/

echo "after build: $(pwd)" 

cd /home/phygital/pm/UI-MVC/

# sudo dotnet /home/phygital/app/Phygital.UI.MVC.dll --urls http://0.0.0.0:5000 2>> /home/phygital/progress.txt

gcloud secrets versions access latest --secret="phygital-secrets" >> /etc/envvar.sh
  
mkdir -p /var/www/phygital
chown -R phygital:phygital /var/www/phygital/
echo "$(ls -la /var/www/phygital)"
cp -r /home/phygital/app/ /var/www/phygital/

cat <<EOF > phygital.service
[Unit]
Description=PM ASP.NET app

[Service]
User=phygital
WorkingDirectory=/home/phygital/pm/UI-MVC/
ExecStart=/usr/bin/dotnet /var/www/phygital/app/Phygital.UI.MVC.dll
Restart=always
EnvironmentFile=/etc/envvar.sh
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
EOF

mv phygital.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable phygital.service
systemctl start phygital.service