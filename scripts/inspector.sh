#!/bin/sh
aws inspector2 create-cis-scan-configuration --schedule "oneTime={}" --scan-name packer --security-level LEVEL_1 --targets "accountIds=$AWS_ACCOUNT_ID,targetResourceTags={packer=$AMI_NAME-$CODEBUILD_BUILD_NUMBER}"

SCANARN=$(aws inspector2 list-cis-scans | jq -r ".scans[] | select(.targets.targetResourceTags.packer==[\"$AMI_NAME-$CODEBUILD_BUILD_NUMBER\"]).scanArn")
echo $SCANARN
STATUS=$(aws inspector2 get-cis-scan-report --scan-arn $SCANARN | jq -r '.status')
echo "$STATUS"

while [ "$STATUS" != "SUCCEEDED" ]
do
  sleep 30
  STATUS=$(aws inspector2 get-cis-scan-report --scan-arn $SCANARN | jq -r '.status')
  echo "$STATUS (wait 30)... "
done

