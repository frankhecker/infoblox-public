#!/bin/sh
# delete_igw_aws.sh: Detach an AWS Internet gateway and delete it.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <igw>"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<igw>: ID or name of Internet gateway"
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
igw=$1

# Check to see if the region was specified incorrectly.
[ -z "${region}" ] && usage
case "${region}" in
    -q)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

# If no gateway with this ID or name exists then we are done.
# If multiple gateways exist, remind user to use an ID to specify it.
# Otherwise detach the gateway from its VPC and delete it.
existing=`sh "${dir}"/list_igw_aws.sh -q -r "${region}" "${igw}"`
if [ -z "${existing}" ]; then
    [ "${quiet}" = false ] && echo >&2 "${fn}: ${igw}: Internet gateway does not exist"
    exit 1
fi
case "${existing}" in
    *\ *)
        echo >&2 "${fn}: ${gateway}: multiple gateways with this name, use ID"
        echo "${existing}"
        exit 1
        ;;
    *) igw_id="${existing}" ;;
esac

# If the gateway is attached to a VPC, detach it.
vpc_id=`sh "${dir}"/list_igw_aws.sh -l -r "${region}" "${igw_id}" \
    | cut -f2`
if [ "${vpc_id}" != "None" ]; then
    aws ec2 detach-internet-gateway \
        --internet-gateway-id "${igw_id}" \
        --vpc-id "${vpc_id}"
fi
if [ $? -ne 0  ]; then
    echo >&2 "${fn}: ${igw_id}: could not detach from VPC ${vpc_id}"
    exit 1
fi

# Delete the (now-detached) Internet gateway.
aws ec2 delete-internet-gateway --internet-gateway-id "${igw_id}"
