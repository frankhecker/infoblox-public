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
* `list_igw_aws.sh`: List Internet gateway IDs and (optionally) their
  names and the VPCs they're attached to.

Examples of how to use these scripts:

    # List VPC IDs in us-east-2 region, one per line
    list_vpc_aws.sh -r us-east-2 -1

    # List info for VPC in default region with address 10.192.0.0/20
    list_vpc_aws.sh -l 10.192.0.0/20

    # List VPC ID(s) for VPC(s) with name tag value "My VPC"
    list_vpc_aws.sh "My VPC"

    # List info for all subnets in us-east-2 region
    list_subnet_aws.sh -r us-east-2 -l

    # List info for subnet(s) in VPC 10.192.0.0/20 with name "My Subnet"
    list_vpc_aws.sh -l -v 10.192.0.0/20 "My Subnet"

    # List subnet IDs in VPC vpc-020f5bab08c0d3f43 in region us-west-1
    list_vpc_aws.sh -v vpc-020f5bab08c0d3f43 -r us-west-1

    # Create a VPC 10.192.0.0/20 in default region
    create_vpc_aws.sh 10.192.0.0/20

    # Create a VPC 10.128.0.0/20 in us-west-2 region with name "My VPC"
    create_vpc_aws.sh -r us-west-2 10.128.0.0/20 "My VPC"

    # Delete the VPC 10.192.0.0/20 in default region
    delete_vpc_aws.sh 10.192.0.0/20

    # Delete the VPC in us-west-2 region with name "My VPC"
    delete_vpc_aws.sh -r us-west-2 "My VPC"

    # Delete the VPC vpc-020f5bab08c0d3f43 in us-west-1 region
    delete_vpc_aws.sh -r us-west-1 vpc-020f5bab08c0d3f43

    # Create a subnet 10.192.1.0/24 in "My VPC" with name "My Subnet"
    create_vpc_aws.sh "My VPC" 10.192.1.0/24 "My Subnet"

    # Delete the subnet 10.128.1.0/24 in us-west-1 region
    delete_vpc_aws.sh -r us-west-1 10.128.1.0/24

    # List info about Internet gateways in the us-east-2 region.
    list_igw_aws.sh -l -r us-east-2

    # List ID of Internet gateway attached to VPC 10.192.16.0/20.
    list_igw_aws.sh -v 10.192.16.0/20

As implied above, the scripts allow VPCs, subnets, and gateways to be
identified by ID, name (i.e., the value of the "Name" tag), or address
(if applicable). The scripts properly handle cases where the name
contains spaces or the name or (if applicable) address are duplicated
across multiple VPCs, subnets, or gateways.

There are also some test scripts to verify proper functioning of the
above scripts.

Running the scripts requires that a current version of the AWS CLI be
installed (<https://aws.amazon.com/cli/>). At present the scripts also
require that a script `~/set-aws-variables.sh` be present and set the
value of the variable REGION to the desired default AWS region (e.g.,
"us-west-2") and the value of the variable CREATOR to the desired
creator userid (e.g., "jdoe").
