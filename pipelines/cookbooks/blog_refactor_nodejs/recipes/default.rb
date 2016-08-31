include_recipe 'apt'
include_recipe 'nodejs'
include_recipe 'nodejs::npm'

script 'install cfn-init' do
  interpreter "bash"
  code <<-EOH
    apt-get -y install python-setuptools
    wget -P /root https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
    mkdir -p /root/aws-cfn-bootstrap-latest
    tar xvfz /root/aws-cfn-bootstrap-latest.tar.gz --strip-components=1 -C /root/aws-cfn-bootstrap-latest
    easy_install /root/aws-cfn-bootstrap-latest/
  EOH
end
execute 'cfn-init' do
end

# global npm installations
%w{jslint forever forever-monitor}.each do |pkg|
  nodejs_npm pkg
end

# local npm installations
%w{config mysql}.each do |pkg|
  nodejs_npm pkg do
    path "#{node[:blog_refactor_nodejs][:folder]}/app"
  end
end

template "#{node[:blog_refactor_nodejs][:folder]}/app/config/default.json" do
  source 'default.json.erb'
  mode '755'
end

execute 'application startup' do
  command "forever start --sourceDir #{node[:blog_refactor_nodejs][:folder]} index.js"
end
