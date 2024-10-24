#!/bin/bash
#Name: jenkins.sh
#Author: Abdelrahman Gaber
#Purpose: install jenkins.service on Redhat
#Exit Codes: 
#   - 0: Success
#   - 1: jenkins.service failed
####################################################
# Check servicie status
# Argument :
#   Service Name: jenkins
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
# Add Jenkins repo and gpg-key
#############################################################
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
##############################################################
# Add required dependencies for the jenkins package
##############################################################
sudo yum install fontconfig java-17-openjdk -y
sudo yum install jenkins -y
sudo systemctl daemon-reload -y
###############################################################
# Configure Firewall
# Jenkins default port 8080/tcp
###############################################################
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
###############################################################
# Start Service
###############################################################
systemctl enable --now jenkins
###############################################################
# Test Service
###############################################################
service_status jenkins
exit 0