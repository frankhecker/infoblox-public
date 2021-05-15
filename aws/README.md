# infoblox-public/aws

Utility scripts for working with AWS using the AWS CLI.

* `list_vpc_aws.sh`: List VPC IDs and (optionally) VPC addresses and
  names.
* `list_subnet_aws.sh`: List subnet IDs and (optionally) subnet
  addresses and names.

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

As implied above, the scripts allow VPCs and subnets to be identified
by ID, address, or name (i.e., the value of the "Name" tag). The
scripts properly handle cases where the name contains spaces or is
duplicated across multiple VPCs or subnets.

There are also some test scripts to verify proper functioning of the
above scripts.

Running the scripts requires that a current version of the AWS CLI be
installed (<https://aws.amazon.com/cli/>). At present the scripts also
require that a script `~/set-aws-variables.sh` be present and set the
value of the variable REGION to the desired default AWS region.
