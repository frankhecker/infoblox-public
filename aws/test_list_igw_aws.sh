#!/bin/sh"
# test_list_igw_aws.sh: Unit tests of list_igw_aws.sh script."

echo "--- all gateways in default region"
sh list_igw_aws.sh || echo "*** failed"

echo "--- all gateways in default region, one per line"
sh list_igw_aws.sh -1 || echo "*** failed"

echo "--- all gateways in default region, with extra info"
sh list_igw_aws.sh -l || echo "*** failed"

echo "--- gateway with ID in default region"
sh list_igw_aws.sh igw-01c262ece9b51f75e || echo "*** failed"

echo "--- gateway with ID in default region, one per line"
sh list_igw_aws.sh -1 igw-01c262ece9b51f75e || echo "*** failed"

echo "--- gateway with ID in default region, with extra info"
sh list_igw_aws.sh -l igw-01c262ece9b51f75e || echo "*** failed"

echo "--- gateway with name in default region"
sh list_igw_aws.sh test-igw || echo "*** failed"

echo "--- gateway with name in default region, one per line"
sh list_igw_aws.sh -1 test-igw || echo "*** failed"

echo "--- gateway with name in default region, with extra info"
sh list_igw_aws.sh -l test-igw || echo "*** failed"

echo "--- gateway with name in default region, not attached to VPC"
sh list_igw_aws.sh -l test-igw-2 || echo "*** failed"

echo "--- gateway with name containing spaces in default region"
sh list_igw_aws.sh "Test IGW" || echo "*** failed"

echo "--- gateway with name containing spaces in default region, one per line"
sh list_igw_aws.sh -1 "Test IGW" || echo "*** failed"

echo "--- gateway with name containing spaces in default region, with extra info"
sh list_igw_aws.sh -l "Test IGW" || echo "*** failed"

echo "--- Gateways with same name in default region"
sh list_igw_aws.sh igw-with-duplicate-name || echo "*** failed"

echo "--- Gateways with same name in default region, one per line"
sh list_igw_aws.sh -1 igw-with-duplicate-name || echo "*** failed"

echo "--- Gateways with same name in default region, with extra info"
sh list_igw_aws.sh -l igw-with-duplicate-name || echo "*** failed"

echo "--- all gateways in us-east-2 region"
sh list_igw_aws.sh -r us-east-2 || echo "*** failed"

echo "--- all gateways in us-east-2 region, one per line"
sh list_igw_aws.sh -1 -r us-east-2 || echo "*** failed"

echo "--- all gateways in us-east-2 region, with extra info"
sh list_igw_aws.sh -l -r us-east-2 || echo "*** failed"

echo "--- gateway with ID in us-east-2 region"
sh list_igw_aws.sh -r us-east-2 igw-0d22b630817ce49d2 || echo "*** failed"

echo "--- gateway with ID in us-east-2 region, one per line"
sh list_igw_aws.sh -1 -r us-east-2 igw-0d22b630817ce49d2 || echo "*** failed"

echo "--- gateway with ID in us-east-2 region, with extra info"
sh list_igw_aws.sh -l -r us-east-2 igw-0d22b630817ce49d2 || echo "*** failed"

echo "--- gateway with name in us-east-2 region"
sh list_igw_aws.sh -r us-east-2 test-igw || echo "*** failed"

echo "--- gateway with name in us-east-2 region, one per line"
sh list_igw_aws.sh -1 -r us-east-2 test-igw || echo "*** failed"

echo "--- gateway with name in us-east-2 region, with extra info"
sh list_igw_aws.sh -l -r us-east-2 test-igw || echo "*** failed"

echo "--- gateway with name in us-east-2 region, not attached to VPC"
sh list_igw_aws.sh -l -r us-east-2 test-igw-2 || echo "*** failed"

echo "--- gateway with name containing spaces in us-east-2 region"
sh list_igw_aws.sh -r us-east-2 "Test IGW" || echo "*** failed"

echo "--- gateway with name containing spaces in us-east-2 region, one per line"
sh list_igw_aws.sh -1 -r us-east-2 "Test IGW" || echo "*** failed"

echo "--- gateway with name containing spaces in us-east-2 region, with extra info"
sh list_igw_aws.sh -l -r us-east-2 "Test IGW" || echo "*** failed"

echo "--- Gateways with same name in us-east-2 region"
sh list_igw_aws.sh -r us-east-2 igw-with-duplicate-name || echo "*** failed"

echo "--- Gateways with same name in us-east-2 region, one per line"
sh list_igw_aws.sh -1 -r us-east-2 igw-with-duplicate-name || echo "*** failed"

echo "--- Gateways with same name in us-east-2 region, with extra info"
sh list_igw_aws.sh -l -r us-east-2 igw-with-duplicate-name || echo "*** failed"

echo "--- all gateways attached to test-vpc VPC"
sh list_igw_aws.sh -v test-vpc || echo "*** failed"

echo "--- all gateways attached to test-vpc VPC, one per line"
sh list_igw_aws.sh -1 -v test-vpc || echo "*** failed"

echo "--- all gateways attached to test-vpc VPC, with extra info"
sh list_igw_aws.sh -l -v test-vpc || echo "*** failed"

echo "--- gateway with ID attached to test-vpc VPC"
sh list_igw_aws.sh -v test-vpc igw-0d22b630817ce49d2 || echo "*** failed"

echo "--- gateway with ID attached to test-vpc VPC, one per line"
sh list_igw_aws.sh -1 -v test-vpc igw-0d22b630817ce49d2 || echo "*** failed"

echo "--- gateway with ID attached to test-vpc VPC, with extra info"
sh list_igw_aws.sh -l -v test-vpc igw-0d22b630817ce49d2 || echo "*** failed"

echo "--- gateway with name attached to test-vpc VPC"
sh list_igw_aws.sh -v test-vpc test-igw || echo "*** failed"

echo "--- gateway with name attached to test-vpc VPC, one per line"
sh list_igw_aws.sh -1 -v test-vpc test-igw || echo "*** failed"

echo "--- gateway with name attached to test-vpc VPC, with extra info"
sh list_igw_aws.sh -l -v test-vpc test-igw || echo "*** failed"

echo "--- gateway with name containing spaces attached to VPC"
sh list_igw_aws.sh -v "Test VPC" "Test IGW" || echo "*** failed"

echo "--- gateway with name containing spaces attached to VPC, one per line"
sh list_igw_aws.sh -1 -v "Test VPC" "Test IGW" || echo "*** failed"

echo "--- gateway with name containing spaces attached to VPC, with extra info"
sh list_igw_aws.sh -l -v "Test VPC" "Test IGW" || echo "*** failed"

echo "--- Command with invalid option"
sh list_igw_aws.sh -2 && echo "*** failed"

echo "--- Command with no region after -r"
sh list_igw_aws.sh -r -1 && echo "*** failed"

echo "--- Command with no VPC after -v"
sh list_igw_aws.sh -v -1 && echo "*** failed"

echo "--- Command with more than one positional argument"
sh list_igw_aws.sh 10.192.0.0/24 10.192.1.0/24 && echo "*** failed"

echo "--- Command with non-existent gateway ID"
sh list_igw_aws.sh iwg-xxxxxxxxxxxxxxxxx && echo "*** failed"

echo "--- Command with non-existent gateway name"
sh list_igw_aws.sh not-a-igw && echo "*** failed"
