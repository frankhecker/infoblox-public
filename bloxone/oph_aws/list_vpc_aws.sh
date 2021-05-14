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
    echo >&2 "<vpc>: AWS VPC ID, CIDR-format address, or Name tag value"
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
vpc=
while getopts "1lr:" arg; do
    case "${arg}" in
	1) one_per_line=true ;;
	l) long_listing=true ;;
	r) REGION="${OPTARG}" ;;
	*) usage ;;
    esac
done
shift `expr ${OPTIND} - 1`

# Get VPC ID/address/name if specified.
# NOTE: The name may contain spaces if quoted on the command line.
[ $# -gt 1 ] && usage
vpc="$1"

# Check to see if the region was specified incorrectly.
[ -z "${REGION}" -o "${REGION}" = "-1" -o "${REGION}" = "-l" ] && usage

# If no <vpc> argument then list all VPCs, optionally displaying one
# per line and extra info. Otherwise look for the specified VPC(s) by
# ID, CIDR address, and name, optionally displaying extra info.
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
	    --query 'Vpcs[].VpcId' \
	    | tr '\t' ' '
    fi
else
    # Try to find the VPC by ID, CIDR-format address, or name.
    # NOTE: A search by name may return multiple VPC IDs.
    for vpc_designator in vpc-id cidr tag:Name; do
	vpc_ids=`aws ec2 describe-vpcs --no-paginate --output text \
            --region "${REGION}" \
            --filters "Name=${vpc_designator},Values=${vpc}" \
            --query 'Vpcs[].VpcId'`
        [ ! -z "${vpc_ids}" ] && break
    done
    if [ -z "${vpc_ids}" ]; then
        echo >&2 "${fn}: ${vpc} not found"
        exit 1
    fi

    # Handle the case of multiple IDs based on the display options.
    if [ "${long_listing}" = true ]; then
	# NOTE: --vpc-ids allows multiple VPC IDs to be specified.
	aws ec2 describe-vpcs --no-paginate --output text \
	    --region "${REGION}" \
	    --vpc-ids ${vpc_ids} \
	    --query 'Vpcs[].[VpcId, CidrBlock, (Tags[?Key==`Name`].Value)[0]]'
    elif [ "${one_per_line}" = true ]; then
	for vpc_id in ${vpc_ids}; do
	    echo "${vpc_id}"
	done
    else
	echo ${vpc_ids}
    fi
fi
