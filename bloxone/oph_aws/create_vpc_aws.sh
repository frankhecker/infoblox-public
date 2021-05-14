#!/bin/sh
# create_vpc_aws.sh: Create a VPC in AWS.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Get variables needed for AWS access to our region/VPC/subnets.
source ${HOME}/.aws/set-aws-variables.sh

# Print usage information if needed.
usage() {
    echo >2 "Usage: ${fn} <cidr> [-n name]"
    echo >2 "<cidr>: VPC CIDR-format address"
    echo >2 "<name>: VPC name tag in AWS"
    exit 1
}

# Get positional arguments.
[ $# -lt 1 ] && usage
vpc_cidr=$2
shift 1

# Default values for optional parameters.
vpc_name=`whoami`-${REGION}-vpc

# Check and extract arguments.
while getopts "n:" arg; do
    case $arg in
	n)
	    vpc_name=${OPTARG}
	    ;;
	*)
	    usage
	    ;;
    esac
done

# Make the script's directory our working directory.
# NOTE: Other scripts invoked below should be in the same directory.
cd ${dir}

# Create the VPC.
aws ec2 create-vpc \
    --cidr-block ${vpc_cidr} \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${vpc_name}},{Key=creator,Value=${CREATOR}}]" \
    --query 'Vpc.VpcId' \
    --output text
