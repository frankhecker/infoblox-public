#!/bin/sh
# list_subnet_aws.sh: List subnet(s) in an AWS region.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-1] [-l] [-r <region>] [<subnet>]"
    echo >&2 "-1: print subnet ids one per line"
    echo >&2 "-l: also print subnet CIDR and Name tag (implies -1)"
    echo >&2 "<region>: AWS region"
    echo >&2 "<subnet>: Name tag value or CIDR-format address of subnet"
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

# Get subnet name/address argument if specified.
# TODO: Make sure everything works if the subnet name contains spaces.
[ $# -gt 1 ] && usage
subnet="$1"

# Check to see if the region was specified incorrectly.
[ -z "${REGION}" -o "${REGION}" = "-1" -o "${REGION}" = "-l" ] && usage

# If no <subnet> argument, list all subnets, displaying one per line
# and with extra info if specified. Otherwise look for the specified
# subnet by name or CIDR address and display extra info if specified.
# TODO: Deal with the case where multiple subnets have the same name.
if [ -z "${subnet}" ]; then
    if [ "${long_listing}" = true ]; then
	aws ec2 describe-subnets --no-paginate --output text \
	    --region "${REGION}" \
	    --query 'Subnets[].[SubnetId, CidrBlock, (Tags[?Key==`Name`].Value)[0], VpcId]'
    elif [ "${one_per_line}" = true ]; then
	aws ec2 describe-subnets --no-paginate --output text \
	    --region "${REGION}" \
	    --query 'Subnets[].SubnetId' \
	    | tr '\t' '\n'
    else
	aws ec2 describe-subnets --no-paginate --output text \
	    --region "${REGION}" \
	    --query 'Subnets[].SubnetId'
    fi
else
    # Look for the subnet first by CIDR-format address and then by name.
    subnet_id=`aws ec2 describe-subnets --no-paginate --output text \
        --region "${REGION}" \
	--filters "Name=cidr,Values=${subnet}" \
	--query 'Subnets[].SubnetId'`
    if [ -z "${subnet_id}" ]; then
	subnet_id=`aws ec2 describe-subnets --no-paginate --output text \
	    --region "${REGION}" \
            --filters "Name=tag:Name,Values=${subnet}" \
            --query 'Subnets[].SubnetId'`
	if [ -z "${subnet_id}" ]; then
            echo >&2 "${fn}: ${subnet} not found"
            exit 1
	fi
    fi
    if [ "${long_listing}" = true ]; then
	aws ec2 describe-subnets --no-paginate --output text \
	    --region "${REGION}" \
	    --subnet-ids "${subnet_id}" \
	    --query 'Subnets[].[SubnetId, CidrBlock, (Tags[?Key==`Name`].Value)[0], VpcId]'
    else
	echo "${subnet_id}"
    fi
fi
