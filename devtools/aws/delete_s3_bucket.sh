#!/bin/sh
name=$1

if [ -z "$name" ]; then
  echo missing argument name
  exit
fi

has_bucket=$(aws s3api list-buckets --region eu-central-1 | jq -r '. | .Buckets | map( . | select(.Name == "'$name'")) | .[].Name' )
if [ ! -z "$has_bucket" ]; then
  aws s3api delete-bucket --region eu-central-1 --bucket $name || exit
  echo "deleted bucket $name"
else
  echo "no bucket $name found"
fi

has_user=$(aws iam list-users | jq -r '. | .Users | map( . | select(.UserName == "'$name'")) | .[].UserName' )
if [ ! -z "$has_user" ]; then
  access_key_id="$(aws iam list-access-keys --user-name $name | jq -r '. | .AccessKeyMetadata[0].AccessKeyId')"
  if [ ! -z "$access_key_id" ] && [ ! $access_key_id == "null" ]; then
    aws iam delete-access-key --user-name $name --access-key-id $access_key_id || exit
    echo "deleted iam user access key $name"
  fi
  policy=$(aws iam list-user-policies --user-name $name | jq -r '. | .PolicyNames[0]' )
  if [ ! -z "$policy" ] && [ ! $policy == "null" ]; then
    aws iam delete-user-policy --user-name $name --policy-name $policy
    echo "deleted iam user policy $name"
  fi
  aws iam delete-user --user-name $name || exit
  echo "deleted iam user $name"
else
  echo "no iam user $name found"
fi

cloudfront_id=$(aws cloudfront list-distributions | jq -r '.DistributionList.Items | map( . | select(.Origins.Items[].Id=="'$name'")) | .[].Id')
if [ ! -z "$cloudfront_id" ] && [ ! "$cloudfront_id" == "null" ]; then
  tmpfile=$(mktemp)
  tmpfile2=$(mktemp)
  aws cloudfront get-distribution-config --id $cloudfront_id | jq .DistributionConfig.Enabled=false > $tmpfile
  etag="$(jq .ETag $tmpfile -r)"
  jq -r .DistributionConfig $tmpfile > $tmpfile2
  etag2="$(aws cloudfront update-distribution --id $cloudfront_id --if-match $etag --distribution-config file://$tmpfile2 | jq -r '. | .ETag')"
  echo "waiting for cloudfront beeing disabled..."
  aws cloudfront wait distribution-deployed --id $cloudfront_id
  aws cloudfront delete-distribution --id $cloudfront_id --if-match $etag2
  rm $tmpfile $tmpfile2
  echo "deleted cloudfront $name"
else
  echo "no cloundfront $name found"
fi
