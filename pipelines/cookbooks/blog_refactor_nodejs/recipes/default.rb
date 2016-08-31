include_recipe 'apt'
include_recipe 'nodejs'
include_recipe 'nodejs::npm'

# global npm installations
%w{jslint forever forever-monitor}.each do |pkg|
  nodejs_npm pkg
end

# local npm installations
%w{config mysql}.each do |pkg|
  nodejs_npm pkg do
    path "#{node[:blog_refactor_nodejs][:folder]}"
  end
end

template "#{node[:blog_refactor_nodejs][:folder]}/app/config/default.json" do
  source 'default.json.erb'
  mode '755'
end

execute "application startup" do
  command "forever start --sourceDir #{node[:blog_refactor_nodejs][:folder]} index.js"
end
