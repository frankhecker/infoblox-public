#!/bin/sh
# create_igw_aws.sh: Create AWS Internet gateway and attach it to a VPC.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <vpc> [<name>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<vpc>: VPC to attach Internet gateway to"
    echo >&2 "<name>: Internet gateway name"
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
vpc=$1
name=$2

# Check to see if the region was specified incorrectly.
[ -z "${region}" ] && usage
case "${region}" in
    -q)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

# Look for the VPC ID to which the gateway should be attached.
vpc_id=`sh "${dir}"/list_vpc_aws.sh -q -r "${region}" "${vpc}"`
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

# If Internet gateway exists and is attached to VPC, output ID.
existing=`sh "${dir}"/list_igw_aws.sh -q -r "${region}" -v "${vpc_id}"`
if [ ! -z "${existing}" ]; then
    [ "${quiet}" = false ] && echo >&2 "${fn}: ${vpc_id}: Internet gateway already attached to VPC"
    echo "${existing}"
    exit 1
fi

# If other gateways with specified name exist, do not create this one.
if [ ! -z "${name}" ]; then
    existing=`sh "${dir}"/list_igw_aws.sh -q -r "${region}" "${name}"`
    if [ ! -z "${existing}" ]; then
        echo >&2 "${fn}: ${name}: not created, name is same as ${existing}"
        exit 1
    fi
fi

# Create the Internet gateway.
if [ -z "${name}" ]; then
    igw_id=`aws ec2 create-internet-gateway \
        --no-paginate --output text \
        --region "${region}" \
        --query 'InternetGateway.InternetGatewayId'`
else
    igw_id=`aws ec2 create-internet-gateway \
        --no-paginate --output text \
        --region "${region}" \
        --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${name}},{Key=creator,Value=${creator}}]" \
        --query 'InternetGateway.InternetGatewayId'`
fi

# If gateway was created, attach it to the specified VPC.
if [ -z "${igw_id}" ]; then
    echo >&2 "${fn}: error creating Internet gateway"
    exit 1
else
    aws ec2 attach-internet-gateway \
        --internet-gateway-id "${igw_id}" \
        --vpc-id "${vpc_id}"
    echo "${igw_id}"
fi
