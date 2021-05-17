#!/bin/sh"
# test_list_vpc_aws.sh: Unit tests of list_vpc_aws.sh script."

echo "--- all VPCs in default region"
sh list_vpc_aws.sh || echo "*** failed"

echo "--- all VPCs in default region, one per line"
sh list_vpc_aws.sh -1 || echo "*** failed"

echo "--- all VPCs in default region, with extra info"
sh list_vpc_aws.sh -l || echo "*** failed"

echo "--- VPC with ID in default region"
sh list_vpc_aws.sh vpc-0a61f335fa05e57df || echo "*** failed"

echo "--- VPC with ID in default region, one per line"
sh list_vpc_aws.sh -1 vpc-0a61f335fa05e57df || echo "*** failed"

echo "--- VPC with ID in default region, with extra info"
sh list_vpc_aws.sh -l vpc-0a61f335fa05e57df || echo "*** failed"

echo "--- VPC with address in default region"
sh list_vpc_aws.sh 10.192.0.0/20 || echo "*** failed"

echo "--- VPC with address in default region, one per line"
sh list_vpc_aws.sh -1 10.192.0.0/20 || echo "*** failed"

echo "--- VPC with address in default region, with extra info"
sh list_vpc_aws.sh -1 10.192.0.0/20 || echo "*** failed"

echo "--- VPC with name in default region"
sh list_vpc_aws.sh test-vpc || echo "*** failed"

echo "--- VPC with name in default region, one per line"
sh list_vpc_aws.sh -1 test-vpc || echo "*** failed"

echo "--- VPC with name in default region, with extra info"
sh list_vpc_aws.sh -l test-vpc || echo "*** failed"

echo "--- VPC with name containing spaces in default region"
sh list_vpc_aws.sh "Test VPC" || echo "*** failed"

echo "--- VPC with name containing spaces in default region, one per line"
sh list_vpc_aws.sh -1 "Test VPC" || echo "*** failed"

echo "--- VPC with name containing spaces in default region, with extra info"
sh list_vpc_aws.sh -l "Test VPC" || echo "*** failed"

echo "--- VPCs with same name in default region"
sh list_vpc_aws.sh vpc-with-duplicate-name || echo "*** failed"

echo "--- VPCs with same name in default region, one per line"
sh list_vpc_aws.sh -1 vpc-with-duplicate-name || echo "*** failed"

echo "--- VPCs with same name in default region, with extra info"
sh list_vpc_aws.sh -l vpc-with-duplicate-name || echo "*** failed"

echo "--- all VPCs in us-east-2 region"
sh list_vpc_aws.sh || echo "*** failed"

echo "--- all VPCs in us-east-2 region, one per line"
sh list_vpc_aws.sh -1 || echo "*** failed"

echo "--- all VPCs in us-east-2 region, with extra info"
sh list_vpc_aws.sh -l || echo "*** failed"

echo "--- VPC with ID in us-east-2 region"
sh list_vpc_aws.sh vpc-0a61f335fa05e57df || echo "*** failed"

echo "--- VPC with ID in us-east-2 region, one per line"
sh list_vpc_aws.sh -1 vpc-0a61f335fa05e57df || echo "*** failed"

echo "--- VPC with ID in us-east-2 region, with extra info"
sh list_vpc_aws.sh -l vpc-0a61f335fa05e57df || echo "*** failed"

echo "--- VPC with address in us-east-2 region"
sh list_vpc_aws.sh -r us-east-2 10.192.0.0/20 || echo "*** failed"

echo "--- VPC with address in us-east-2 region, one per line"
sh list_vpc_aws.sh -1 -r us-east-2 10.192.0.0/20 || echo "*** failed"

echo "--- VPC with address in us-east-2 region, with extra info"
sh list_vpc_aws.sh -l -r us-east-2 10.192.0.0/20 || echo "*** failed"

echo "--- VPC with name in us-east-2 region"
sh list_vpc_aws.sh -r us-east-2 test-vpc || echo "*** failed"

echo "--- VPC with name in us-east-2 region, one per line"
sh list_vpc_aws.sh -1 -r us-east-2 test-vpc || echo "*** failed"

echo "--- VPC with name in us-east-2 region, with extra info"
sh list_vpc_aws.sh -l -r us-east-2 test-vpc || echo "*** failed"

echo "--- VPC with name containing spaces in us-east-2 region"
sh list_vpc_aws.sh -r us-east-2 "Test VPC" || echo "*** failed"

echo "--- VPC with name containing spaces in us-east-2 region, one per line"
sh list_vpc_aws.sh -1 -r us-east-2 "Test VPC" || echo "*** failed"

echo "--- VPC with name containing spaces in us-east-2 region, with extra info"
sh list_vpc_aws.sh -l -r us-east-2 "Test VPC" || echo "*** failed"

echo "--- VPCs with same name in us-east-2 region"
sh list_vpc_aws.sh -r us-east-2 vpc-with-duplicate-name || echo "*** failed"

echo "--- VPCs with same name in us-east-2 region, one per line"
sh list_vpc_aws.sh -1 -r us-east-2 vpc-with-duplicate-name || echo "*** failed"

echo "--- VPCs with same name in us-east-2 region, with extra info"
sh list_vpc_aws.sh -l -r us-east-2 vpc-with-duplicate-name || echo "*** failed"

echo "--- Command with invalid option"
sh list_vpc_aws.sh -2 && echo "*** failed"

echo "--- Command with no region after -r"
sh list_vpc_aws.sh -r -1 && echo "*** failed"

echo "--- Command with more than one positional argument"
sh list_vpc_aws.sh 10.192.0.0/20 10.192.64.0/20 && echo "*** failed"

echo "--- Command with non-existent VPC ID"
sh list_vpc_aws.sh vpc-xxxxxxxxxxxxxxxxx && echo "*** failed"

echo "--- Command with non-existent VPC CIDR address"
sh list_vpc_aws.sh 10.192.0.0/16 && echo "*** failed"

echo "--- Command with non-existent VPC name"
sh list_vpc_aws.sh not-a-vpc && echo "*** failed"
