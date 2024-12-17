#!/bin/bash
packer build \ 
-var "SECURITY_GROUP_ID=${SECURITY_GROUP_ID}" \
-var "VPC_ID=${VPC_ID}" \
-var "SUBNET_ID=${SUBNET_ID}" \
-var "PLAYBOOK=${CODEBUILD_SRC_DIR_playbook}/site.yml" \
-var "BUILDNUM=${CODEBUILD_BUILD_NUMBER}" \
-var "AMI=${AMI_NAME}" \
-var "INSTANCE_PROFILE=${INSTANCE_PROFILE}" \
${PROJECT_NAME}.pkr.hcl 