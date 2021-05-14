#!/bin/sh
# launch-ubuntu-aws.sh: Launch an Ubuntu 20.04 AWS EC2 instance.

# Filename of script and the directory in its path as invoked.
# NOTE: If script is invoked by filename only then ${dir} will be '.'.
fn=`basename $0`
dir=`dirname $0`

# Print usage information if needed.
usage() {
    echo "Usage: ${fn} <host> <subnet> <script> [-t <type>] [-d <size>]"
    echo "<host>: name tag in AWS"
    echo "<subnet>: CIDR-format address of subnet for host"
    echo "<script>: shell script to configure the host"
    echo "<type>: AWS instance type (default is t2.micro)"
    echo "<size>: disk size for instance in GB (default is 32)"
    exit 1
}

# Get positional arguments.
[ $# -lt 3 ] && usage
host_name=$1
subnet=$2
script=$3
shift 3

# Get absolute path for script.
script_path="$(cd "$(dirname "${script}")"; pwd)/$(basename "${script}")"

# Default values for optional parameters.
instance_type=t2.micro
disk_size=32

# Check and extract arguments.
while getopts "t:d:" arg; do
    case $arg in
	t)
	    instance_type=${OPTARG}
	    ;;
	d)
	    disk_size=${OPTARG}
	    ;;
	*)
	    usage
	    ;;
    esac
done

# Make the script's directory our working directory.
# NOTE: Other scripts invoked below should be in the same directory.
cd ${dir}

# Get variables needed for AWS access to our region/VPC/subnets.
source ${HOME}/.aws/set-aws-variables.sh

# Use official Canonical Ubuntu 20.04 LTS AMI for specified AWS region.
ami=`aws ec2 describe-images \
    --owners 099720109477 \
    --region ${REGION} \
    --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04*' \
    --query 'sort_by(Images, &CreationDate)[-1].[CreationDate,Name,ImageId]' \
    --output text \
    | cut -f3`

# Determine which subnet ID to use based on the specified subnet.
echo "subnet: ${subnet}"
subnet_id=`aws ec2 describe-subnets | \
    jq -r '.Subnets[] | select(.CidrBlock == "'${subnet}'") | .SubnetId'`
echo "subnet_id: ${subnet_id}"
if [ -z $subnet_id ]
then
    echo "${fn}: unknown subnet ${subnet}"
    exit 1
fi

# Launch the host instance.
aws ec2 run-instances \
    --image-id ${ami} \
    --instance-type ${instance_type} \
    --subnet-id ${subnet_id} \
    --associate-public-ip-address \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=${disk_size},VolumeType=gp2}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${host_name}},{Key=creator,Value=${CREATOR}},{Key=lifecycle,Value=poc}]" \
    --key-name ${KEY_PAIR} \
    --user-data file://${script_path} \
    --query 'Instances[0].InstanceId' \
    --output text

