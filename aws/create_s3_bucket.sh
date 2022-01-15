#!/bin/sh
name=$1

if [ -z "$name" ]; then
  echo missing argument name
fi

templates="$HOME/scripts/aws/templates"
cp $templates/bucketpolicy.json $templates/cors.json $templates/cloudfront.json $templates/userpolicy.json .

# create s3 bucket
aws s3api create-bucket \
  --region eu-central-1 --bucket $name \
  --create-bucket-configuration LocationConstraint=eu-central-1 > /dev/null

# bucket policy
sed -i "s/%bucket%/$name/g" bucketpolicy.json
aws s3api put-bucket-policy --bucket $name --policy file://bucketpolicy.json > /dev/null

# cors
# sed -i "s/%name%/$name/g" cors.json
aws s3api put-bucket-cors --bucket $name --cors-configuration file://cors.json > /dev/null

echo "created bucket $name"

# create IAM User
aws iam create-user --user-name $name > /dev/null
accessRes=$(aws iam create-access-key --user-name $name)
accesskey=$( echo $accessRes | jq -r '.AccessKey.AccessKeyId' )
accesssecret=$( echo $accessRes | jq -r '.AccessKey.SecretAccessKey' )

# iam s3 bucket user policy
sed -i "s/%bucket%/$name/g" userpolicy.json
aws iam put-user-policy --user-name $name --policy-name $name --policy-document file://userpolicy.json > /dev/null

echo "created iam user $name"

# cloudfront
sed -i "s/%bucket%/$name/g" cloudfront.json
cloudfrontRes=$(aws cloudfront create-distribution --distribution-config file://cloudfront.json)
cloudfront=$( echo $cloudfrontRes | jq -r '.Distribution.DomainName' )
cloudfrontid=$( echo $cloudfrontRes | jq -r '.Distribution.Id' )

echo "created cloudfront $name"

# cleanup
rm bucketpolicy.json cors.json cloudfront.json userpolicy.json

echo $accesskey | pass insert hostinghelden/aws/s3/$name/accesskey -e > /dev/null
echo $accesssecret | pass insert hostinghelden/aws/s3/$name/accesssecret -e > /dev/null

echo "accesskey: $accesskey"
echo "accesssecret: $accesssecret"
echo "cloudfront_url: $cloudfront"
echo "cloudfront_id: $cloudfrontid"
