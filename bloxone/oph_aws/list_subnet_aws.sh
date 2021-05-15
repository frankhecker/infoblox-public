#!/bin/sh
# list_subnet_aws.sh: List subnet(s) in an AWS region.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-1] [-l] [-r <region>] [-v vpc] [<subnet>]"
    echo >&2 "-1: print subnet ids one per line"
    echo >&2 "-l: also print subnet's VPC, address, and name (implies -1)"
    echo >&2 "-r <region>: AWS region to search"
    echo >&2 "-v <vpc>: VPC ID, address, or name to search"
    echo >&2 "<subnet>: Subnet ID, address, or name to list"
    exit 1
}

# Get added variables needed for AWS access, including default region.
# NOTE: Credentials should be in the standard AWS-specified locations.
# TODO: Remove the need for this extra file if possible.
source "${HOME}"/.aws/set-aws-variables.sh

# Check and extract optional arguments.
one_per_line=false
long_listing=false
# REGION=(default value comes from set-aws-variable.sh)
vpc=
while getopts "1lr:v:" arg; do
    case "${arg}" in
        1) one_per_line=true ;;
        l) long_listing=true ;;
        r) REGION="${OPTARG}" ;;
        v) vpc="${OPTARG}" ;;
        *) usage ;;
    esac
done
shift `expr ${OPTIND} - 1`

# Get subnet name/address argument if specified.
# TODO: Make sure everything works if the subnet name contains spaces.
[ $# -gt 1 ] && usage
subnet="$1"

# Check to see if the region or VPC were specified incorrectly.
[ -z "${REGION}" -o "${REGION}" = "-1" -o "${REGION}" = "-l" ] && usage
[ "${vpc}" = "-1" -o "${vpc}" = "-l" ] && usage

# If a VPC was specified, find it by ID, address, or name.
# NOTE: A search by name may return multiple VPC IDs.
if [ -z "${vpc}" ]; then
    vpc_ids=
else
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
fi

# If no <subnet> argument then list all subnets, optionally displaying
# one per line and extra info. Otherwise look for the specified
# subnet(s) by ID, address, and name, optionally displaying extra
# info. In either event handle the case where the search is done in
# one or more VPCs.
if [ -z "${subnet}" ]; then
    if [ "${long_listing}" = true ]; then
        if [ -z "${vpc_ids}" ]; then
            aws ec2 describe-subnets --no-paginate --output text \
                --region "${REGION}" \
                --query 'Subnets[].[SubnetId, CidrBlock, VpcId, (Tags[?Key==`Name`].Value)[0]]'
        else
            for vpc_id in ${vpc_ids}; do
                aws ec2 describe-subnets --no-paginate --output text \
                    --region "${REGION}" \
                    --filters "Name=vpc-id,Values=${vpc_id}" \
                    --query 'Subnets[].[SubnetId, VpcId, CidrBlock, (Tags[?Key==`Name`].Value)[0]]'
            done
        fi
    elif [ "${one_per_line}" = true ]; then
        if [ -z "${vpc_ids}" ]; then
            aws ec2 describe-subnets --no-paginate --output text \
                --region "${REGION}" \
                --query 'Subnets[].SubnetId' \
            | tr '\t' '\n'
        else
            for vpc_id in ${vpc_ids}; do
                aws ec2 describe-subnets --no-paginate --output text \
                    --region "${REGION}" \
                    --filters "Name=vpc-id,Values=${vpc_id}" \
                    --query 'Subnets[].SubnetId' \
                | tr '\t' '\n'
            done
        fi
    else
        if [ -z "${vpc_ids}" ]; then
            aws ec2 describe-subnets --no-paginate --output text \
                --region "${REGION}" \
                --query 'Subnets[].SubnetId' \
            | tr '\t' ' '
        else
            subnet_ids=
            for vpc_id in ${vpc_ids}; do
                new_subnet_ids=`aws ec2 describe-subnets --no-paginate --output text \
                    --region "${REGION}" \
                    --filters "Name=vpc-id,Values=${vpc_id}" \
                    --query 'Subnets[].SubnetId' \
                | tr '\t' ' '`
                if [ -z "$subnet_ids" ]; then
                    subnet_ids="${new_subnet_ids}"
                else
                    subnet_ids="${subnet_ids} ${new_subnet_ids}"
                fi
            done
            echo ${subnet_ids}
        fi
    fi
else
    # Try to find the subnet by ID, address, or name.
    # NOTE: A search by name may return multiple subnet IDs.
    if [ -z "${vpc_ids}" ]; then
        for subnet_designator in subnet-id cidr tag:Name; do
            subnet_ids=`aws ec2 describe-subnets --no-paginate --output text \
                            --region "${REGION}" \
                            --filters "Name=${subnet_designator},Values=${subnet}" \
                            --query 'Subnets[].SubnetId'`
            [ ! -z "${subnet_ids}" ] && break
        done
    else
        subnet_ids=
        for vpc_id in ${vpc_ids}; do
            for subnet_designator in subnet-id cidr tag:Name; do
                new_subnet_ids=`aws ec2 describe-subnets --no-paginate --output text \
                        --region "${REGION}" \
                        --filters \
                            "Name=vpc-id,Values=${vpc_id}" \
                            "Name=${subnet_designator},Values=${subnet}" \
                        --query 'Subnets[].SubnetId'`
                [ ! -z "${new_subnet_ids}" ] && break
            done
            if [ -z "$subnet_ids" ]; then
                subnet_ids="${new_subnet_ids}"
            else
                subnet_ids="${subnet_ids} ${new_subnet_ids}"
            fi
        done
    fi
    if [ -z "${subnet_ids}" ]; then
        echo >&2 "${fn}: ${subnet} not found"
        exit 1
    fi

    # Handle the case of multiple IDs based on the display options.
    if [ "${long_listing}" = true ]; then
        # NOTE: --subnet-ids allows multiple subnet IDs to be specified.
        aws ec2 describe-subnets --no-paginate --output text \
            --region "${REGION}" \
            --subnet-ids ${subnet_ids} \
            --query 'Subnets[].[SubnetId, VpcId, CidrBlock, (Tags[?Key==`Name`].Value)[0]]'
    elif [ "${one_per_line}" = true ]; then
        for subnet_id in ${subnet_ids}; do
            echo "${subnet_id}"
        done
    else
        echo ${subnet_ids}
    fi
fi
