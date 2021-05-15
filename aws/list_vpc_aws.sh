#!/bin/sh
# list_vpc_aws.sh: List VPCs in an AWS region.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-1] [-l] [-r <region>] [<vpc>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-1: display VPC ids one per line"
    echo >&2 "-l: also display VPC's address and name (implies -1)"
    echo >&2 "-r <region>: AWS region to search"
    echo >&2 "<vpc>: VPC ID, address, or name to list"
    exit 1
}

# Get added variables needed for AWS access, including default region.
# NOTE: Credentials should be in the standard AWS-specified locations.
# TODO: Remove the need for this extra file if possible.
source "${HOME}"/.aws/set-aws-variables.sh

# Check and extract optional arguments.
quiet=false
one_per_line=false
long_listing=false
# Default value of REGION comes from set-aws-variable.sh.
vpc=
while getopts "q1lr:" arg; do
    case "${arg}" in
        q) quiet=true ;;
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
[ -z "${REGION}" ] && usage
case "${REGION}" in 
    -q|-1|-l|-v)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

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
    # NOTE: A search by address or name may return multiple VPC IDs.
    for vpc_designator in vpc-id cidr tag:Name; do
        vpc_ids=`aws ec2 describe-vpcs --no-paginate --output text \
            --region "${REGION}" \
            --filters "Name=${vpc_designator},Values=${vpc}" \
            --query 'Vpcs[].VpcId'`
        [ ! -z "${vpc_ids}" ] && break
    done
    if [ -z "${vpc_ids}" ]; then
        [ "${quiet}" = false ] && echo >&2 "${fn}: ${vpc} not found"
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
