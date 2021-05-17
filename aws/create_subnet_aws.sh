#!/bin/sh
# create_subnet_aws.sh: Create a subnet in an AWS VPC.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <vpc> <cidr> [<name>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<vpc>: VPC ID, address, or name"
    echo >&2 "<cidr>: subnet CIDR-format address"
    echo >&2 "<name>: VPC name"
    exit 1
}

# Get added variables needed for AWS access, including default region.
# NOTE: Credentials should be in the standard AWS-specified locations.
# TODO: Remove the need for this extra file if possible.
source "${HOME}"/.aws/set-aws-variables.sh

# Check and extract optional arguments.
# REGION=(default value of REGION comes from set-aws-variable.sh)
quiet=false
while getopts "qr:" arg; do
    case "${arg}" in
        q) quiet=true ;;
        r) REGION="${OPTARG}" ;;
        *) usage ;;
    esac
done
shift `expr ${OPTIND} - 1`

# Get positional arguments.
[ $# -lt 2 -o $# -gt 3 ] && usage
vpc=$1
subnet_cidr=$2
subnet_name=$3

# Check to see if the region was specified incorrectly.
[ -z "${REGION}" ] && usage
case "${REGION}" in
    -q)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

# Look for the VPC ID in which to create the subnet.
vpc_id=`sh "${dir}"/list_vpc_aws.sh -q -r "${REGION}" "${vpc}"`
if [ -z "${vpc_id}" ]; then
    echo >&2 "${fn}: ${vpc}: VPC not found"
    exit 1
fi

# If multiple VPCs exist, remind user to use an ID to specify the VPC.
case "${vpc_id}" in
    *\ *)
        echo >&2 "${fn}: ${vpc}: multiple VPCs with this address/name, use ID"
        echo >&2 "${vpc_id}"
        exit 1
        ;;
esac

# If subnets with specified address already exist, output IDs.
existing=`sh "${dir}"/list_subnet_aws.sh -q -r "${REGION}" -v "${vpc_id}" "${subnet_cidr}"`
if [ ! -z "${existing}" ]; then
    [ "${quiet}" = false ] && echo >&2 "${fn}: ${subnet_cidr}: subnet exists"
    echo "${existing}"
    exit 1
fi

# If other subnets with specified name exist, do not create this one.
if [ ! -z "${subnet_name}" ]; then
    existing=`sh "${dir}"/list_subnet_aws.sh -q -r "${REGION}" -v "${vpc_id}" "${subnet_name}"`
    if [ ! -z "${existing}" ]; then
        echo >&2 "${fn}: ${subnet_cidr}: not created, name is same as ${existing}"
        exit 1
    fi
fi

# Create the subnet.
if [ -z "${subnet_name}" ]; then
    aws ec2 create-subnet \
        --no-paginate --output text \
        --region "${REGION}" \
        --vpc-id "${vpc_id}" \
        --cidr-block "${subnet_cidr}" \
        --query 'Subnet.SubnetId'
else
    aws ec2 create-subnet \
        --no-paginate --output text \
        --region "${REGION}" \
        --vpc-id "${vpc_id}" \
        --cidr-block "${subnet_cidr}" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${subnet_name}},{Key=creator,Value=${CREATOR}}]" \
        --query 'Subnet.SubnetId'
fi
