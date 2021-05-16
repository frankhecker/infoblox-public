# infoblox-public/aws

Utility scripts for working with AWS using the AWS CLI.

* `list_vpc_aws.sh`: List VPC IDs and (optionally) VPC addresses and
  names.
* `list_subnet_aws.sh`: List subnet IDs and (optionally) subnet
  addresses and names.
* `create_vpc_aws.sh`: Create a VPC and optionally give it a name
* `create_subnet_aws.sh`: Create a subnet and optionally give it a name
* `delete_vpc_aws.sh`: Delete a VPC by ID, address, or name.
* `delete_subnet_aws.sh`: Delete a subnet by ID, address, or name.

Examples of how to use these scripts:

    # List VPC IDs in us-east-2 region, one per line
    sh list_vpc_aws.sh -r us-east-2 -1

    # List info for VPC in default region with address 10.192.0.0/20
    sh list_vpc_aws.sh -l 10.192.0.0/20

    # List VPC ID(s) for VPC(s) with name tag value "My VPC"
    sh list_vpc_aws.sh "My VPC"

    # List info for all subnets in us-east-2 region
    sh list_subnet_aws.sh -r us-east-2 -l

    # List info for subnet(s) in VPC 10.192.0.0/20 with name "My Subnet"
    sh list_vpc_aws.sh -l -v 10.192.0.0/20 "My Subnet"

    # List subnet IDs in VPC vpc-020f5bab08c0d3f43 in region us-west-1
    sh list_vpc_aws.sh -v vpc-020f5bab08c0d3f43 -r us-west-1

    # Create a VPC 10.192.0.0/20 in default region
    sh create_vpc_aws.sh 10.192.0.0/20

    # Create a VPC 10.128.0.0/20 in us-west-2 region with name "My VPC"
    sh create_vpc_aws.sh -r us-west-2 10.128.0.0/20 "My VPC"

    # Delete the VPC 10.192.0.0/20 in default region
    sh delete_vpc_aws.sh 10.192.0.0/20

    # Delete the VPC in us-west-2 region with name "My VPC"
    sh delete_vpc_aws.sh -r us-west-2 "My VPC"

    # Delete the VPC vpc-020f5bab08c0d3f43 in us-west-1 region
    sh delete_vpc_aws.sh -r us-west-1 vpc-020f5bab08c0d3f43

    # Create a subnet 10.192.1.0/24 in "My VPC" with name "My Subnet"
    sh create_vpc_aws.sh "My VPC" 10.192.1.0/24 "My Subnet"

    # Delete the subnet 10.128.1.0/24 in us-west-1 region
    sh delete_vpc_aws.sh -r us-west-1 10.128.1.0/24

As implied above, the scripts allow VPCs and subnets to be identified
by ID, address, or name (i.e., the value of the "Name" tag). The
scripts properly handle cases where the name contains spaces or the
name or address are duplicated across multiple VPCs or subnets.

There are also some test scripts to verify proper functioning of the
above scripts.

Running the scripts requires that a current version of the AWS CLI be
installed (<https://aws.amazon.com/cli/>). At present the scripts also
require that a script `~/set-aws-variables.sh` be present and set the
value of the variable REGION to the desired default AWS region (e.g.,
"us-west-2") and the value of the variable CREATOR to the desired
creator userid (e.g., "jdoe").
