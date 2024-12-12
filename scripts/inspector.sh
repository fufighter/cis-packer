#!/bin/bash
ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
echo $ACCOUNTID

aws inspector2 create-cis-scan-configuration --schedule "oneTime={}" --scan-name packer --security-level LEVEL_1 --targets "accountIds=$ACCOUNTID,targetResourceTags={packer=$AMI_NAME-$CODEBUILD_BUILD_NUMBER}"
sleep 5

SCAN_ARN=$(aws inspector2 list-cis-scans | jq -r ".scans[] | select(.targets.targetResourceTags.packer==[\"${AMI_NAME}-${CODEBUILD_BUILD_NUMBER}\"]).scanArn")
echo scanarn $SCAN_ARN
  
while [[ -z "$SCAN_ARN" ]]
do
  SCAN_ARN=$(aws inspector2 list-cis-scans | jq -r ".scans[] | select(.targets.targetResourceTags.packer==[\"${AMI_NAME}-${CODEBUILD_BUILD_NUMBER}\"]).scanArn")
  echo scanarn $SCAN_ARN
done

aws sts get-caller-identity

STATUS=$(aws inspector2 get-cis-scan-report --scan-arn $SCAN_ARN | jq -r '.status')
echo "$STATUS"

while [ "$STATUS" != "SUCCEEDED" ]
do
  sleep 30
  STATUS=$(aws inspector2 get-cis-scan-report --scan-arn $SCAN_ARN | jq -r '.status')
  echo "$STATUS (wait 30)... "
done