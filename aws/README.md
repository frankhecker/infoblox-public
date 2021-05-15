# infoblox-public/aws

Utility scripts for working with AWS using the AWS CLI.

* `list_vpc_aws.sh`: List VPC IDs and (optionally) VPC addresses and
  names.

There are also some test scripts to verify proper functioning of the
above scripts.

Running the scripts requires that a current version of the AWS CLI be
installed (<https://aws.amazon.com/cli/>). At present the scripts also
require that a script `~/set-aws-variables.sh` be present and set the
value of the variable REGION to the desired default AWS region.
