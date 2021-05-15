#!/bin/sh"
# test_list_subnet_aws.sh: Unit tests of list_subnet_aws.sh script."

echo "--- all subnets in default region"
sh list_subnet_aws.sh || echo "*** failed"

echo "--- all subnets in default region, one per line"
sh list_subnet_aws.sh -1 || echo "*** failed"

echo "--- all subnets in default region, with extra info"
sh list_subnet_aws.sh -l || echo "*** failed"

echo "--- subnet with ID in default region"
sh list_subnet_aws.sh subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with ID in default region, one per line"
sh list_subnet_aws.sh -1 subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with ID in default region, with extra info"
sh list_subnet_aws.sh -l subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with address in default region"
sh list_subnet_aws.sh 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with address in default region, one per line"
sh list_subnet_aws.sh -1 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with address in default region, with extra info"
sh list_subnet_aws.sh -1 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with name in default region"
sh list_subnet_aws.sh test-subnet || echo "*** failed"

echo "--- subnet with name in default region, one per line"
sh list_subnet_aws.sh -1 test-subnet || echo "*** failed"

echo "--- subnet with name in default region, with extra info"
sh list_subnet_aws.sh -l test-subnet || echo "*** failed"

echo "--- subnet with name containing spaces in default region"
sh list_subnet_aws.sh "Test Subnet" || echo "*** failed"

echo "--- subnet with name containing spaces in default region, one per line"
sh list_subnet_aws.sh -1 "Test Subnet" || echo "*** failed"

echo "--- subnet with name containing spaces in default region, with extra info"
sh list_subnet_aws.sh -l "Test Subnet" || echo "*** failed"

echo "--- Subnets with same name in default region"
sh list_subnet_aws.sh subnet-with-duplicate-name || echo "*** failed"

echo "--- Subnets with same name in default region, one per line"
sh list_subnet_aws.sh -1 subnet-with-duplicate-name || echo "*** failed"

echo "--- Subnets with same name in default region, with extra info"
sh list_subnet_aws.sh -l subnet-with-duplicate-name || echo "*** failed"

echo "--- all subnets in us-east-2 region"
sh list_subnet_aws.sh -r us-east-2 || echo "*** failed"

echo "--- all subnets in us-east-2 region, one per line"
sh list_subnet_aws.sh -1 -r us-east-2 || echo "*** failed"

echo "--- all subnets in us-east-2 region, with extra info"
sh list_subnet_aws.sh -l -r us-east-2 || echo "*** failed"

echo "--- subnet with ID in us-east-2 region"
sh list_subnet_aws.sh -r us-east-2 subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with ID in us-east-2 region, one per line"
sh list_subnet_aws.sh -1 -r us-east-2 subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with ID in us-east-2 region, with extra info"
sh list_subnet_aws.sh -l -r us-east-2 subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with address in us-east-2 region"
sh list_subnet_aws.sh -r us-east-2 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with address in us-east-2 region, one per line"
sh list_subnet_aws.sh -1 -r us-east-2 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with address in us-east-2 region, with extra info"
sh list_subnet_aws.sh -l -r us-east-2 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with name in us-east-2 region"
sh list_subnet_aws.sh -r us-east-2 test-subnet || echo "*** failed"

echo "--- subnet with name in us-east-2 region, one per line"
sh list_subnet_aws.sh -1 -r us-east-2 test-subnet || echo "*** failed"

echo "--- subnet with name in us-east-2 region, with extra info"
sh list_subnet_aws.sh -l -r us-east-2 test-subnet || echo "*** failed"

echo "--- subnet with name containing spaces in us-east-2 region"
sh list_subnet_aws.sh -r us-east-2 "Test Subnet" || echo "*** failed"

echo "--- subnet with name containing spaces in us-east-2 region, one per line"
sh list_subnet_aws.sh -1 -r us-east-2 "Test Subnet" || echo "*** failed"

echo "--- subnet with name containing spaces in us-east-2 region, with extra info"
sh list_subnet_aws.sh -l -r us-east-2 "Test Subnet" || echo "*** failed"

echo "--- Subnets with same name in us-east-2 region"
sh list_subnet_aws.sh -r us-east-2 subnet-with-duplicate-name || echo "*** failed"

echo "--- Subnets with same name in us-east-2 region, one per line"
sh list_subnet_aws.sh -1 -r us-east-2 subnet-with-duplicate-name || echo "*** failed"

echo "--- Subnets with same name in us-east-2 region, with extra info"
sh list_subnet_aws.sh -l -r us-east-2 subnet-with-duplicate-name || echo "*** failed"

echo "--- all subnets in test-vpc VPC"
sh list_subnet_aws.sh -v test-vpc || echo "*** failed"

echo "--- all subnets in test-vpc VPC, one per line"
sh list_subnet_aws.sh -1 -v test-vpc || echo "*** failed"

echo "--- all subnets in test-vpc VPC, with extra info"
sh list_subnet_aws.sh -l -v test-vpc || echo "*** failed"

echo "--- subnet with ID in test-vpc VPC"
sh list_subnet_aws.sh -v test-vpc subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with ID in test-vpc VPC, one per line"
sh list_subnet_aws.sh -1 -v test-vpc subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with ID in test-vpc VPC, with extra info"
sh list_subnet_aws.sh -l -v test-vpc subnet-07fa0f7e149dca45d || echo "*** failed"

echo "--- subnet with address in test-vpc VPC"
sh list_subnet_aws.sh -v test-vpc 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with address in test-vpc VPC, one per line"
sh list_subnet_aws.sh -1 -v test-vpc 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with address in test-vpc VPC, with extra info"
sh list_subnet_aws.sh -l -v test-vpc 10.192.0.0/24 || echo "*** failed"

echo "--- subnet with name in test-vpc VPC"
sh list_subnet_aws.sh -v test-vpc test-subnet || echo "*** failed"

echo "--- subnet with name in test-vpc VPC, one per line"
sh list_subnet_aws.sh -1 -v test-vpc test-subnet || echo "*** failed"

echo "--- subnet with name in test-vpc VPC, with extra info"
sh list_subnet_aws.sh -l -v test-vpc test-subnet || echo "*** failed"

echo "--- subnet with name containing spaces in test-vpc VPC"
sh list_subnet_aws.sh -v test-vpc "Test Subnet" || echo "*** failed"

echo "--- subnet with name containing spaces in test-vpc VPC, one per line"
sh list_subnet_aws.sh -1 -v test-vpc "Test Subnet" || echo "*** failed"

echo "--- subnet with name containing spaces in test-vpc VPC, with extra info"
sh list_subnet_aws.sh -l -v test-vpc "Test Subnet" || echo "*** failed"

echo "--- Subnets with same name in test-vpc VPC"
sh list_subnet_aws.sh -v test-vpc subnet-with-duplicate-name || echo "*** failed"

echo "--- Subnets with same name in test-vpc VPC, one per line"
sh list_subnet_aws.sh -1 -v test-vpc subnet-with-duplicate-name || echo "*** failed"

echo "--- Subnets with same name in test-vpc VPC, with extra info"
sh list_subnet_aws.sh -l -v test-vpc subnet-with-duplicate-name || echo "*** failed"

echo "--- Command with invalid option"
sh list_subnet_aws.sh -2 && echo "*** failed"

echo "--- Command with no region after -r"
sh list_subnet_aws.sh -r -1 && echo "*** failed"

echo "--- Command with no VPC after -v"
sh list_subnet_aws.sh -v -1 && echo "*** failed"

echo "--- Command with more than one positional argument"
sh list_subnet_aws.sh 10.192.0.0/24 10.192.1.0/24 && echo "*** failed"

echo "--- Command with non-existent subnet ID"
sh list_subnet_aws.sh subnet-xxxxxxxxxxxxxxxxx && echo "*** failed"

echo "--- Command with non-existent subnet address"
sh list_subnet_aws.sh 10.192.0.0/20 && echo "*** failed"

echo "--- Command with non-existent subnet name"
sh list_subnet_aws.sh not-a-subnet && echo "*** failed"
