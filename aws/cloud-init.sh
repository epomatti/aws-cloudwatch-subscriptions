#!/usr/bin/env bash
su ec2-user

sudo yum makecache
sudo yum update && sudo yum upgrade -y

# https://docs.aws.amazon.com/linux/al2023/release-notes/all-packages-al2023-20230517.html
# sudo yum -y install postgresql15 telnet
