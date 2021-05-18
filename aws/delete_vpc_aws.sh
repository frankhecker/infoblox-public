#!/bin/sh
# delete_vpc_aws.sh: Delete a VPC in AWS.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <vpc>"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<vpc>: ID, address, or name of VPC"
    exit 1
}

# Get default region.
region=`aws configure list | grep '^ *region' | awk '{ print $2 }'`

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
[ $# -ne 1 ] && usage
vpc=$1

# Check to see if the region was specified incorrectly.
[ -z "${region}" ] && usage
case "${region}" in
    -q)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

# If no VPC with this ID, address, or name exists then we are done.
# If multiple VPCs exist, remind user to use an ID to specify the VPC.
# Otherwise delete the VPC.
existing=`sh "${dir}"/list_vpc_aws.sh -q -r "${region}" "${vpc}"`
if [ -z "${existing}" ]; then
    [ "${quiet}" = false ] && echo >&2 "${fn}: ${vpc}: VPC does not exist"
    exit 1
fi
case "${existing}" in
    *\ *)
        echo >&2 "${fn}: ${vpc}: multiple VPCs with this address/name, use ID"
        echo "${existing}"
        exit 1
        ;;
    *)
        aws ec2 delete-vpc --region "${region}" --vpc-id "${existing}"
        ;;
esac
