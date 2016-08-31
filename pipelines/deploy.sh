#bin/bash

# these environment variables should be in the script executor's profile
export AWS_REGION="us-east-1"
export AWS_VPC_ID="vpc-857a3ee2"
export AWS_SUBNET_IDS="subnet-c5a76a8c,subnet-3b233a06"
export AWS_AZS="us-east-1c,us-east-1b"
export AWS_KEYPAIR="example.pem"

# set up local variables
app_name=blog_refactor_nodejs
repository_url=https://github.com/stelligent/${app_name}
repository_branch=master
aws_region=${AWS_REGION:-us-east-1}
aws_vpc=${AWS_VPC_ID}
aws_subnets=${AWS_SUBNET_IDS}
aws_azs=${AWS_AZS}
aws_keypair=${AWS_KEYPAIR}

# fetch source code:
rm -rf .working-folder
git clone --branch ${repository_branch} --depth 1 ${repository_url} .working-folder

# perform static analysis on the code
pushd ./.working-folder
  foodcritic -t ~FC001 pipelines/cookbooks/${app_name}
  find . -name "*.js" -print0 | xargs -0 jslint
popd

# create a timestamp for naming the application's CloudFormation stack
stamp=$(date +%Y%m%d%H%M%s)

# run aws cli for cloudformation of ASG
asg_stack_name="${app_name}-${stamp}"
cfn_template=${DEPLOY_TEMPLATE:./cfn/deploy-app.template}
aws cloudformation create-stack \
  --disable-rollback \
  --region ${aws_region} \
  --stack-name ${asg_stack_name} \
  --template-body file://${cfn_template} \
  --capabilities CAPABILITY_IAM \
  --tags \
    Key="application",Value=${app_name} \
    Key="branch",Value=${repository_branch} \
  --parameters \
    ParameterKey=VpcId,ParameterValue=${aws_vpc} \
    ParameterKey=AWSKeyPair,ParameterValue=${aws_keypair} \
    ParameterKey=ASGSubnetIds,ParameterValue=\"${aws_subnets}\" \
    ParameterKey=ASGAvailabilityZones,ParameterValue=\"${aws_azs}\" \
    ParameterKey=AppName,ParameterValue=${app_name} \
    ParameterKey=PropertyStr,ParameterValue=${PropertyStr:-banjo} \
    ParameterKey=PropertyNum,ParameterValue=${PropertyNum:-144} \
    ParameterKey=PropertyBool,ParameterValue=${PropertyBool:-true} \
    ParameterKey=PropertyUrl,ParameterValue=${PropertyUrl:-https://jqplay.org/} \
    
aws cloudformation wait stack-create-complete --stack-name ${asg_stack_name}

elb_dns=$(cat rds.tmp | jq '.Stacks[0].Outputs[] | select(.OutputKey == "DNSName") | .OutputValue')
elb_url="https://%{elb_dns}/:8080"

# post-deploy smoke test
curl -O elb_url