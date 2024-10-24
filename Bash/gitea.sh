#!/bin/bash
#Name: gitea.sh
#Author: Abdelrahman Gaber
#Purpose: install gitea.service on Redhat
#Exit Codes: 
#   - 0: Success
#   - 1: Gitea.service failed
####################################################
# Check servicie status
# Argument :
#   Service Name: Gitea
####################################################
function service_status() {
    status=$(sudo systemctl is-active $1)
    if [ $status = "active" ]
    then
        echo "$1 service is running"
    else
        echo "$1 service isnot active"
        exit 1
    fi
}
#############################################################
# Install git
#############################################################
yum install -y git

#############################################################
# Download Gitea
#############################################################
mkdir /opt/gitea
cd /opt/gitea
wget -O gitea https://dl.gitea.com/gitea/1.22.2/gitea-1.22.2-linux-amd64
chmod +x gitea
##############################################################
# Create service account for gitea
##############################################################
groupadd --system git
adduser \
   --system \
   --shell /bin/bash \
   --comment 'Git Version Control' \
   --gid git \
   --home-dir /home/git \
   --create-home \
   git
##############################################################   
# Create configuration file structure
##############################################################
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea
touch /etc/gitea/app.ini
chown git:git /etc/gitea/app.ini
chmod 750 /etc/gitea
chmod 640 /etc/gitea/app.ini
cp /opt/gitea/gitea /usr/local/bin/gitea
chown git:git /usr/local/bin/gitea
################################################################
# Create gitea service file
cat <<EOF > /etc/systemd/system/gitea.service
[Unit]
Description=Gitea (Git with a cup of tea)
After=network.target
###
# Don't forget to add the database service dependencies
###
#Wants=mysql.service
#After=mysql.service
#Wants=mariadb.service
#After=mariadb.service
#Wants=postgresql.service
#After=postgresql.service
#Wants=memcached.service
#After=memcached.service
#Wants=redis.service
#After=redis.service
###
# If using socket activation for main http/s
###
#After=gitea.main.socket
#Requires=gitea.main.socket
###
# (You can also provide gitea an http fallback and/or ssh socket too)
# An example of /etc/systemd/system/gitea.main.socket
###
##
## [Unit]
## Description=Gitea Web Socket
## PartOf=gitea.service
##
## [Socket]
## Service=gitea.service
## ListenStream=<some_port>
## NoDelay=true
##
## [Install]
## WantedBy=sockets.target
[Service]
# Uncomment the next line if you have repos with lots of files and get a HTTP 500 error because of that
# LimitNOFILE=524288:524288
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
# If using Unix socket: tells systemd to create the /run/gitea folder, which will contain the gitea.sock file
# (manually creating /run/gitea doesn't work, because it would not persist across reboots)
#RuntimeDirectory=gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea
# If you install Git to directory prefix other than default PATH (which happens
# for example if you install other versions of Git side-to-side with
# distribution version), uncomment below line and add that prefix to PATH
# Don't forget to place git-lfs binary on the PATH below if you want to enable
# Git LFS support
#Environment=PATH=/path/to/git/bin:/bin:/sbin:/usr/bin:/usr/sbin
# If you want to bind Gitea to a port below 1024, uncomment
# the two values below, or use socket activation to pass Gitea its ports as above
###
#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_BIND_SERVICE
###
# In some cases, when using CapabilityBoundingSet and AmbientCapabilities option, you may want to
# set the following value to false to allow capabilities to be applied on gitea process. The following
# value if set to true sandboxes gitea service and prevent any processes from running with privileges
# in the host user namespace.
###
#PrivateUsers=false
###

[Install]
WantedBy=multi-user.target
EOF
###################################################################################################
# Configure Firewall
# Gitea default port 3000/tcp
###################################################################################################
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --reload
###################################################################################################
# Start Service
###################################################################################################
systemctl daemon-reload
systemctl enable --now gitea.service
###################################################################################################
# Test Service
###################################################################################################
service_status gitea
exit 0