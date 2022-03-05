#!/bin/sh
stack_id=$1
name=$2
git=$3
domain=$4

if [ -z "$stack_id" ]; then
  echo missing argument stack_id
  exit 1
fi
if [ -z "$name" ]; then
  echo missing argument name
  exit 1
fi
if [ -z "$git" ]; then
  echo missing argument git
  exit 1
fi
if [ -z "$domain" ]; then
  echo missing argument domain
  exit 1
fi

appid=$(aws opsworks create-app --region eu-central-1 --type other \
   --stack-id $stack_id --name $name \
   --app-source Type=git,Url=$git,Revision=master \
   --domains $domain \
   | jq '.AppId')

# deploy hook
#ssh -i $key ubuntu@git.hostinghelden.at "sudo sh /root/gitdeployhook.sh $name $stackid $appid"

echo "appid: $appid"
