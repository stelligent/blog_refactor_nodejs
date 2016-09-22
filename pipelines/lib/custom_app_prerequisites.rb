module Build
  module Acceptance
    class CustomAppPrerequisites < AppPrerequisites
      require 'json'
      include BlogRefactorGem::Utils::Cfn
      def initialize(store:)
        super(store: store)

        params = store.get(attrib_name: 'params')
        params[:asg_stack_name] = "#{params[:app_name]}-#{Time.now.to_i}"
        params[:chef_json_key] = "#{params[:asg_stack_name]}.json"

        chef_json = {
          run_list: chef_json[:run_list],

          blog_refactor_nodejs: {
            property_str: ENV['property_str'] || "default property_str value",
            property_num: ENV['property_num'] || "default property_num value",
            property_bool: ENV['property_bool'] || 'default property_bool value',
            property_url: ENV['property_url'] || 'https://jqplay.org/'
          }
        }

        Aws::S3::Client.new(region: 'us-east-1').put_object({
          body: chef_json.to_json,
          bucket: "blog-refactor",
          key: "chefjson/#{params[:chef_json_key]}"
        })
      end
    end
  end
end
