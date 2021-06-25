#!/bin/sh
# list_rtb_aws.sh: List route table(s) in an AWS region.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-1] [-l] [-r <region>] [-v vpc] [<rtb>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-1: display route table ids one per line"
    echo >&2 "-l: also display table's VPC (if any) and name (implies -1)"
    echo >&2 "-r <region>: AWS region to search"
    echo >&2 "-v <vpc>: VPC to look for a route table"
    echo >&2 "<rtb>: route table ID or name to list"
    exit 1
}

# Get default region.
region=`aws configure list | grep '^ *region' | awk '{ print $2 }'`

# Check and extract optional arguments.
quiet=false
one_per_line=false
long_listing=false
vpc=
while getopts "q1lr:v:" arg; do
    case "${arg}" in
        q) quiet=true ;;
        1) one_per_line=true ;;
        l) long_listing=true ;;
        r) region="${OPTARG}" ;;
        v) vpc="${OPTARG}" ;;
        *) usage ;;
    esac
done
shift `expr ${OPTIND} - 1`

# Get route table ID/name argument if specified.
# NOTE: The name may contain spaces if quoted on the command line.
[ $# -gt 1 ] && usage
rtb="$1"

# Check to see if the region or VPC were specified incorrectly.
[ -z "${region}" ] && usage
case "${region}" in
    -q|-1|-l|-v)
        echo >&2 "${fn}: -r option missing region"
        usage
        ;;
esac
case "${vpc}" in
    -q|-1|-l|-r)
        echo >&2 "${fn}: -v option missing VPC"
        usage
        ;;
esac

# If a VPC was specified, find it by ID, address, or name.
# NOTE: A search by name or address may return multiple VPC IDs.
if [ -z "${vpc}" ]; then
    vpc_ids=
else
    for vpc_designator in vpc-id cidr tag:Name; do
        vpc_ids=`aws ec2 describe-vpcs --no-paginate --output text \
            --region "${region}" \
            --filters "Name=${vpc_designator},Values=${vpc}" \
            --query 'Vpcs[].VpcId'`
        [ ! -z "${vpc_ids}" ] && break
    done
    if [ -z "${vpc_ids}" ]; then
        [ "${quiet}" = false ] && echo >&2 "${fn}: ${vpc} not found"
        exit 1
    fi
fi

# If no <rtb> argument then list all route tables, optionally
# displaying one per line and with extra info. Otherwise look for the
# specified route table(s) by ID and name, optionally displaying extra
# info. In either event handle the case where the search is done in
# one or more VPCs.
if [ -z "${rtb}" ]; then
    if [ "${long_listing}" = true ]; then
        if [ -z "${vpc_ids}" ]; then
            aws ec2 describe-route-tables \
                --no-paginate --output text \
                --region "${region}" \
                --query 'RouteTables[].[RouteTableId, VpcId, (Tags[?Key==`Name`].Value)[0]]'
        else
            for vpc_id in ${vpc_ids}; do
                aws ec2 describe-route-tables \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters "Name=vpc-id,Values=${vpc_id}" \
                    --query 'RouteTables[].[RouteTableId, VpcId, (Tags[?Key==`Name`].Value)[0]]'
            done
        fi
    elif [ "${one_per_line}" = true ]; then
        if [ -z "${vpc_ids}" ]; then
            aws ec2 describe-route-tables \
                --no-paginate --output text \
                --region "${region}" \
                --query 'RouteTables[].RouteTableId' \
            | tr '\t' '\n'
        else
            for vpc_id in ${vpc_ids}; do
                aws ec2 describe-route-tables \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters "vpc-id,Values=${vpc_id}" \
                    --query 'RouteTable[].RouteTableId' \
                | tr '\t' '\n'
            done
        fi
    else
        # List route table IDs on same line.
        if [ -z "${vpc_ids}" ]; then
            # List all route table IDs.
            aws ec2 describe-route-tables \
                --no-paginate --output text \
                --region "${region}" \
                --query 'RouteTables[].RouteTableId' \
            | tr '\t' ' '
        else
            # List route table ID(s) associated with specified VPC(s).
            rtb_ids=
            for vpc_id in ${vpc_ids}; do
                new_rtb_ids=`aws ec2 describe-route-tables \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters "Name=vpc-id,Values=${vpc_id}" \
                    --query 'RouteTables[].RouteTableId' \
                | tr '\t' ' '`
                if [ -z "$rtb_ids" ]; then
                    rtb_ids="${new_rtb_ids}"
                else
                    rtb_ids="${rtb_ids} ${new_rtb_ids}"
                fi
            done
            echo ${rtb_ids}
        fi
    fi
else
    # Try to find the route table by ID or name.
    # NOTE: A search by name may return multiple route table IDs.
    if [ -z "${vpc_ids}" ]; then
        for rtb_designator in route-table-id tag:Name; do
            rtb_ids=`aws ec2 describe-route-tables \
                --no-paginate --output text \
                --region "${region}" \
                --filters "Name=${rtb_designator},Values=${rtb}" \
                --query 'RouteTables[].RouteTableId'`
            [ ! -z "${rtb_ids}" ] && break
        done
    else
        rtb_ids=
        for vpc_id in ${vpc_ids}; do
            for rtb_designator in route-table-id tag:Name; do
                new_rtb_ids=`aws ec2 describe-route-tables \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters \
                        "Name=${rtb_designator},Values=${rtb}" \
                        "Name=vpc-id,Values=${vpc_id}" \
                    --query 'RouteTables[].RouteTableId'`
                [ ! -z "${new_rtb_ids}" ] && break
            done
            if [ -z "$rtb_ids" ]; then
                rtb_ids="${new_rtb_ids}"
            else
                rtb_ids="${rtb_ids} ${new_rtb_ids}"
            fi
        done
    fi
    if [ -z "${rtb_ids}" ]; then
        [ "${quiet}" = false ] && echo >&2 "${fn}: ${rtb} not found"
        exit 1
    fi

    # Handle the case of multiple IDs based on the display options.
    if [ "${long_listing}" = true ]; then
        # NOTE: --route-table-ids allows multiple IDs to be specified.
        aws ec2 describe-route-tables \
            --no-paginate --output text \
            --region "${region}" \
            --route-table-ids ${rtb_ids} \
            --query 'RouteTables[].[RouteTableId, VpcId, (Tags[?Key==`Name`].Value)[0]]'
    elif [ "${one_per_line}" = true ]; then
        for rtb_id in ${rtb_ids}; do
            echo "${rtb_id}"
        done
    else
        echo ${rtb_ids}
    fi
fi
