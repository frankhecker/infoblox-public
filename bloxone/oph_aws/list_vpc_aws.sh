#!/bin/sh
# list_vpc_aws.sh: List VPCs in an AWS region.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-1] [-l] [-r <region>] [<vpc>]"
    echo >&2 "-1: print VPC ids one per line"
    echo >&2 "-l: also print VPC CIDR and Name tag (implies -1)"
    echo >&2 "<region>: AWS region"
    echo >&2 "<vpc>: Name tag value or CIDR-format address of VPC"
    exit 1
}

# Get added variables needed for AWS access, including default region.
# NOTE: Credentials should be in the standard AWS-specified locations.
# TODO: Remove the need for this extra file if possible.
source "${HOME}"/.aws/set-aws-variables.sh

# Check and extract optional arguments.
one_per_line=false
long_listing=false
# Default value of REGION comes from set-aws-variable.sh.
while getopts "1lr:" arg; do
    case "${arg}" in
	1) one_per_line=true ;;
	l) long_listing=true ;;
	r) REGION="${OPTARG}" ;;
	*) usage ;;
    esac
done
shift `expr ${OPTIND} - 1`

# Get VPC name/address argument if specified.
# TODO: Make sure everything works if the VPC name contains spaces.
[ $# -gt 1 ] && usage
vpc="$1"

# Check to see if the region was specified incorrectly.
[ -z "${REGION}" -o "${REGION}" = "-1" -o "${REGION}" = "-l" ] && usage

# If no <vpc> argument, list all VPCs, displaying one per line and
# with extra info if specified. Otherwise look for the specified VPC
# by name or CIDR address and display extra info if specified.
# TODO: Deal with the case where multiple VPCs have the same name.
if [ -z "${vpc}" ]; then
    if [ "${long_listing}" = true ]; then
	aws ec2 describe-vpcs --no-paginate --output text \
	    --region "${REGION}" \
	    --query 'Vpcs[].[VpcId, CidrBlock, (Tags[?Key==`Name`].Value)[0]]'
    elif [ "${one_per_line}" = true ]; then
	aws ec2 describe-vpcs --no-paginate --output text \
	    --region "${REGION}" \
	    --query 'Vpcs[].VpcId' \
	    | tr '\t' '\n'
    else
	aws ec2 describe-vpcs --no-paginate --output text \
	    --region "${REGION}" \
	    --query 'Vpcs[].VpcId'
    fi
else
    # Look for the VPC first by CIDR-format address and then by name.
    vpc_id=`aws ec2 describe-vpcs --no-paginate --output text \
        --region "${REGION}" \
	--filters "Name=cidr,Values=${vpc}" \
	--query 'Vpcs[].VpcId'`
    if [ -z "${vpc_id}" ]; then
	vpc_id=`aws ec2 describe-vpcs --no-paginate --output text \
	    --region "${REGION}" \
            --filters "Name=tag:Name,Values=${vpc}" \
            --query 'Vpcs[].VpcId'`
	if [ -z "${vpc_id}" ]; then
            echo >&2 "${fn}: ${vpc} not found"
            exit 1
	fi
    fi
    if [ "${long_listing}" = true ]; then
	aws ec2 describe-vpcs --no-paginate --output text \
	    --region "${REGION}" \
	    --vpc-ids "${vpc_id}" \
	    --query 'Vpcs[].[VpcId, CidrBlock, (Tags[?Key==`Name`].Value)[0]]'
    else
	echo "${vpc_id}"
    fi
fi
