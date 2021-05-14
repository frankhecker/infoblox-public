#!/bin/sh
# list_vpc_aws.sh: List VPCs in AWS.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >2 "Usage: ${fn} [-1] [<vpc>]"
    echo >2 "-1: print VPC ids one per line"
    echo >2 "<vpc>: name or CIDR-format address of VPC"
    exit 1
}

# Get arguments.
case $# in
    0)
	vpc=
	ids_per_line=0
	;;
    1)
	if [ $1 = '-1' ];then
	    vpc=
	    ids_per_line=1
        else
	    vpc=$1
	    ids_per_line=0
	fi
	;;
    2)
	if [ $1 != '-1' ]; then
	    usage
	else
	    vpc=$2
	    ids_per_line=1
	fi
	;;
    *)
	usage
	;;
esac

# Make the script's directory our working directory.
# NOTE: Other scripts invoked below should be in the same directory.
cd ${dir}

# Get variables needed for AWS access to our region/VPC/subnets.
source ${HOME}/.aws/set-aws-variables.sh

# If no <vpc> argument list all VPCs, one per line if specified.
# Otherwise look for the specified VPC.
if [ -z ${vpc} ]; then
    if [ ${ids_per_line} -eq 1 ]; then
	aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text \
	    | tr '\t' '\n'
    else
	aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text
    fi
else
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
    echo ${vpc_id}
fi
