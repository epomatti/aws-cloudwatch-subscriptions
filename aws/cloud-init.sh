#!/usr/bin/env bash
su ec2-user

sudo yum makecache
sudo yum update && sudo yum upgrade -y

sudo yum install -y awslogs
