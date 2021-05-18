#!/bin/sh
# create_vpc_aws.sh: Create a VPC in AWS.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <cidr> [<name>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<cidr>: VPC CIDR-format address"
    echo >&2 "<name>: VPC name"
    exit 1
}

# Get default region and creator ID.
region=`aws configure list | grep '^ *region' | awk '{ print $2 }'`
creator=`whoami`

# Check and extract optional arguments.
quiet=false
while getopts "qr:" arg; do
    case "${arg}" in
        q) quiet=true ;;
        r) region="${OPTARG}" ;;
        *) usage ;;
    esac
done
shift `expr ${OPTIND} - 1`

# Get positional arguments.
[ $# -lt 1 -o $# -gt 2 ] && usage
vpc_cidr=$1
vpc_name=$2

# Check to see if the region was specified incorrectly.
[ -z "${region}" ] && usage
case "${region}" in
    -q)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

# If VPCs with specified address already exist, output IDs.
existing=`sh "${dir}"/list_vpc_aws.sh -q -r "${region}" "${vpc_cidr}"`
if [ ! -z "${existing}" ]; then
    [ "${quiet}" = false ] && echo >&2 "${fn}: ${vpc_cidr}: VPC exists"
    echo "${existing}"
    exit 1
fi

# If other VPCs with specified name exist, do not create this one.
if [ ! -z "${vpc_name}" ]; then
    existing=`sh "${dir}"/list_vpc_aws.sh -q -r "${region}" "${vpc_name}"`
    if [ ! -z "${existing}" ]; then
        echo >&2 "${fn}: ${vpc_cidr}: not created, name is same as ${existing}"
        exit 1
    fi
fi

# Create the VPC.
if [ -z "${vpc_name}" ]; then
    aws ec2 create-vpc \
        --no-paginate --output text \
        --region "${region}" \
        --cidr-block "${vpc_cidr}" \
        --query 'Vpc.VpcId'
else
    aws ec2 create-vpc \
        --no-paginate --output text \
        --region "${region}" \
        --cidr-block "${vpc_cidr}" \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${vpc_name}},{Key=creator,Value=${creator}}]" \
        --query 'Vpc.VpcId'
fi
