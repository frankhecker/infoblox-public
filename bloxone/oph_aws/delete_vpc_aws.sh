#!/bin/sh
# delete_vpc_aws.sh: Create a VPC in AWS.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >2 "Usage: ${fn} <vpc>"
    echo >2 "<vpc>: name or CIDR-format address of VPC"
    exit 1
}

# Get positional arguments.
[ $# -ne 1 ] && usage
vpc=$1
shift 1

# Make the script's directory our working directory.
# NOTE: Other scripts invoked below should be in the same directory.
cd ${dir}

# Get variables needed for AWS access to our region/VPC/subnets.
source ${HOME}/.aws/set-aws-variables.sh

# Look for the VPC first by CIDR-format address and then by name.
vpc_id=`aws ec2 describe-vpcs | \
    jq -r '.Vpcs[] | select(.CidrBlock == "'${vpc}'") | .VpcId'`
if [ -z ${vpc_id} ]; then
    vpc_id=`aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=${vpc}" \
        --query 'Vpcs[].VpcId' \
        --output text`
    if [ -z ${vpc_id} ]; then
        echo >2 "${fn}: ${vpc} not found"
        exit 1
    fi
fi

# Delete the VPC.
aws ec2 delete-vpc --vpc-id ${vpc_id}
