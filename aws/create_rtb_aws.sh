#!/bin/sh
# create_rtb_aws.sh: Create AWS route table in a VPC.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <vpc> [<name>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<vpc>: VPC for the route table"
    echo >&2 "<name>: route table name"
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

# Look for the VPC ID for which the route table is to be created.
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

# If route table of specified name exists for the VPC, output its ID.
if [ ! -z "${name}" ]; then
    existing=`sh "${dir}"/list_rtb_aws.sh -q -r "${region}" -v "${vpc_id}" "${name}"`
    if [ ! -z "${existing}" ]; then
        [ "${quiet}" = false ] && echo >&2 "${fn}: route table ${name} already exists"
        echo "${existing}"
        exit 1
    fi
fi

# Create the route table.
if [ -z "${name}" ]; then
    rtb_id=`aws ec2 create-route-table \
        --no-paginate --output text \
        --region "${region}" \
        --vpc-id "${vpc_id}" \
        --query 'RouteTable.RouteTableId'`
else
    rtb_id=`aws ec2 create-route-table \
        --no-paginate --output text \
        --region "${region}" \
        --vpc-id "${vpc_id}" \
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${name}},{Key=creator,Value=${creator}}]" \
        --query 'RouteTable.RouteTableId'`
fi

# If route table was created, return its ID.
if [ -z "${rtb_id}" ]; then
    echo >&2 "${fn}: error creating route table"
    exit 1
else
    echo "${rtb_id}"
fi
