#!/bin/sh
# delete_subnet_aws.sh: Delete a subnet in AWS.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-r region] <subnet>"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-r <region>: AWS region"
    echo >&2 "<subnet>: ID, address, or name of subnet"
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
subnet=$1

# Check to see if the region was specified incorrectly.
[ -z "${region}" ] && usage
case "${region}" in
    -q)
        echo "${fn}: -r option missing region"
        usage
        ;;
esac

# If no subnet with this ID, address, or name exists then we are done.
# If multiple subnets exist, remind user to use an ID to specify it.
# Otherwise delete the subnet.
existing=`sh "${dir}"/list_subnet_aws.sh -q -r "${region}" "${subnet}"`
if [ -z "${existing}" ]; then
    [ "${quiet}" = false ] && echo >&2 "${fn}: ${subnet}: subnet does not exist"
    exit 1
fi
case "${existing}" in
    *\ *)
        echo >&2 "${fn}: ${subnet}: multiple subnets with this address/name, use ID"
        echo "${existing}"
        exit 1
        ;;
    *)
        aws ec2 delete-subnet --region "${region}" --subnet-id "${existing}"
        ;;
esac
