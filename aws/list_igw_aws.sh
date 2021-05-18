#!/bin/sh
# list_igw_aws.sh: List internet gateway(s) in an AWS region.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo >&2 "Usage: ${fn} [-q] [-1] [-l] [-r <region>] [-v vpc] [<igw>]"
    echo >&2 "-q: run quietly without unneeded messages"
    echo >&2 "-1: display IGW ids one per line"
    echo >&2 "-l: also display IGW's VPC (if any) and name (implies -1)"
    echo >&2 "-r <region>: AWS region to search"
    echo >&2 "-v <vpc>: VPC to look for an attached IGW"
    echo >&2 "<igw>: internet gateway ID, address, or name to list"
    exit 1
}

# Get default region.
region=`aws configure list | grep '^ *region' | awk '{ print $2 }'`

# Check and extract optional arguments.
quiet=false
one_per_line=false
long_listing=false
vpc=
while getopts "q1lar:v:" arg; do
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

# Get internet gateway ID/name argument if specified.
# NOTE: The name may contain spaces if quoted on the command line.
[ $# -gt 1 ] && usage
igw="$1"

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

# If no <igw> argument then list all internet gateways, optionally
# displaying one per line and with extra info. Otherwise look for the
# specified gateway(s) by ID and name, optionally displaying extra
# info. In either event handle the case where the search is done in
# one or more VPCs.
if [ -z "${igw}" ]; then
    if [ "${long_listing}" = true ]; then
        if [ -z "${vpc_ids}" ]; then
            # NOTE: To handle the case where gateway is not attached
            # to a VPC, we convert the returned attachments list to a
            # string and then use sed to produce the desired output.
            aws ec2 describe-internet-gateways \
                --no-paginate --output text \
                --region "${region}" \
                --query 'InternetGateways[].[InternetGatewayId, to_string(Attachments[].VpcId), (Tags[?Key==`Name`].Value)[0]]' \
            | sed -e 's/\[\]/None/' -e 's/\["//' -e 's/"\]//'
        else
            for vpc_id in ${vpc_ids}; do
                aws ec2 describe-internet-gateways \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters "Name=attachment.vpc-id,Values=${vpc_id}" \
                    --query 'InternetGateways[].[InternetGatewayId, to_string(Attachments[].VpcId), (Tags[?Key==`Name`].Value)[0]]' \
                | sed -e 's/\[\]/None/' -e 's/\["//' -e 's/"\]//'
            done
        fi
    elif [ "${one_per_line}" = true ]; then
        if [ -z "${vpc_ids}" ]; then
            aws ec2 describe-internet-gateways \
                --no-paginate --output text \
                --region "${region}" \
                --query 'InternetGateways[].InternetGatewayId' \
            | tr '\t' '\n'
        else
            for vpc_id in ${vpc_ids}; do
                aws ec2 describe-internet-gateways \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters "Name=attachment.vpc-id,Values=${vpc_id}" \
                    --query 'InternetGateways[].InternetGatewayId' \
                | tr '\t' '\n'
            done
        fi
    else
        # List Internet gateway IDs on same line.
        if [ -z "${vpc_ids}" ]; then
            # List all Internet gateway IDs.
            aws ec2 describe-internet-gateways \
                --no-paginate --output text \
                --region "${region}" \
                --query 'InternetGateways[].InternetGatewayId' \
            | tr '\t' ' '
        else
            # List gateway ID(s) attached to specified VPC(s).
            igw_ids=
            for vpc_id in ${vpc_ids}; do
                new_igw_ids=`aws ec2 describe-internet-gateways \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters "Name=attachment.vpc-id,Values=${vpc_id}" \
                    --query 'InternetGateways[].InternetGatewayId' \
                | tr '\t' ' '`
                if [ -z "$igw_ids" ]; then
                    igw_ids="${new_igw_ids}"
                else
                    igw_ids="${igw_ids} ${new_igw_ids}"
                fi
            done
            echo ${igw_ids}
        fi
    fi
else
    # Try to find the Internet gateway by ID or name.
    # NOTE: A search by name may return multiple gateway IDs.
    if [ -z "${vpc_ids}" ]; then
        for igw_designator in internet-gateway-id tag:Name; do
            igw_ids=`aws ec2 describe-internet-gateways \
                --no-paginate --output text \
                --region "${region}" \
                --filters "Name=${igw_designator},Values=${igw}" \
                --query 'InternetGateways[].InternetGatewayId'`
            [ ! -z "${igw_ids}" ] && break
        done
    else
        igw_ids=
        for vpc_id in ${vpc_ids}; do
            for igw_designator in internet-gateway-id tag:Name; do
                new_igw_ids=`aws ec2 describe-internet-gateways \
                    --no-paginate --output text \
                    --region "${region}" \
                    --filters \
                        "Name=${igw_designator},Values=${igw}" \
                        "Name=attachment.vpc-id,Values=${vpc_id}" \
                    --query 'InternetGateways[].InternetGatewayId'`
                [ ! -z "${new_igw_ids}" ] && break
            done
            if [ -z "$igw_ids" ]; then
                igw_ids="${new_igw_ids}"
            else
                igw_ids="${igw_ids} ${new_igw_ids}"
            fi
        done
    fi
    if [ -z "${igw_ids}" ]; then
        [ "${quiet}" = false ] && echo >&2 "${fn}: ${igw} not found"
        exit 1
    fi

    # Handle the case of multiple IDs based on the display options.
    if [ "${long_listing}" = true ]; then
        # NOTE: --internet-gateway-ids allows multiple IDs to be specified.
        aws ec2 describe-internet-gateways \
            --no-paginate --output text \
            --region "${region}" \
            --internet-gateway-ids ${igw_ids} \
            --query 'InternetGateways[].[InternetGatewayId, to_string(Attachments[].VpcId), (Tags[?Key==`Name`].Value)[0]]' \
        | sed -e 's/\[\]/None/' -e 's/\["//' -e 's/"\]//'
    elif [ "${one_per_line}" = true ]; then
        for igw_id in ${igw_ids}; do
            echo "${igw_id}"
        done
    else
        echo ${igw_ids}
    fi
fi
