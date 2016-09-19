#bin/bash

# these environment variables should be in the script executor's profile
export AWS_REGION="us-east-1"
export AWS_VPC_ID="vpc-857a3ee2"
export AWS_SUBNET_IDS="subnet-c5a76a8c,subnet-3b233a06"
export AWS_AZS="us-east-1c,us-east-1b"
export AWS_KEYPAIR="dugas-labs"
export GIT_BRANCH="phase1"

# set up local variables
app_name=NodeJSApp
repository_url=https://github.com/stelligent/blog_refactor_nodejs
repository_branch=${GIT_BRANCH:-master}
aws_region=${AWS_REGION:-us-east-1}
aws_vpc=${AWS_VPC_ID}
aws_subnets=${AWS_SUBNET_IDS}
aws_azs=${AWS_AZS}
aws_keypair=${AWS_KEYPAIR}
app_port=8080
working_directory=.working-folder

# fetch source code:
rm -rf .working-folder
git clone --branch ${repository_branch} --depth 1 ${repository_url} ${working_directory}

# perform static analysis on the code
pushd ${working_directory}
  foodcritic -t ~FC001 "pipelines/cookbooks/${app_name}" -P
  find . -name "*.js" -print0 | xargs -0 jslint
popd

# create a timestamp for naming the application's CloudFormation stack
stamp=$(date +%Y%m%d%H%M%s)

# run aws cli for cloudformation of ASG
asg_stack_name="${app_name}-${stamp}"

# but first, generate and push chef.json to s3
echo {} | jq ".run_list = [\"NodeJSApp\"] | .blog_refactor_nodejs = \
  {property_str: \"${PropertyStr:-banjo}\", \
   property_num: \"${PropertyNum:-144}\", \
   property_bool: \"${PropertyBool:-true}\", \
   property_url: \"${PropertyUrl:-https://jqplay.org/}\"}" > ${working_directory}/chef.json

chef_json_key="${asg_stack_name}.json"
aws s3 cp ${working_directory}/chef.json s3://blog-refactor/chefjson/$chef_json_key

cfn_template=${DEPLOY_TEMPLATE:-./cfn/deploy-app.template}
aws cloudformation create-stack \
  --disable-rollback \
  --region ${aws_region} \
  --stack-name ${asg_stack_name} \
  --template-url https://s3.amazonaws.com/blog-refactor/cfntemplates/deploy-app.template.json \
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
    ParameterKey=ChefJsonKey,ParameterValue=${chef_json_key} \
    ParameterKey=GitBranch,ParameterValue=${repository_branch} \
    ParameterKey=GitUrl,ParameterValue=${repository_url} \
    ParameterKey=SecurityGroupPort,ParameterValue=${app_port}

aws cloudformation wait stack-create-complete --stack-name ${asg_stack_name}
echo $(aws cloudformation describe-stacks --stack-name ${asg_stack_name} 2>/dev/null) > .working-folder/app.tmp

elb_dns=$(cat .working-folder/app.tmp | jq '.Stacks[0].Outputs[] | select(.OutputKey == "DNSName") | .OutputValue')
elb_url="http://${elb_dns}:8080/index.js"

# post-deploy smoke test
curl $elb_url
