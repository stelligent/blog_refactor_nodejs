module Build
  module Acceptance
    class CustomEnvironmentConfiguration < EnvironmentConfiguration
      require 'json'
      include BlogRefactorGem::Utils::Cfn
      def initialize(store:)
        super(store: store)

        params = store.get(attrib_name: 'params')
        params[:asg_stack_name] = "#{params[:app_name]}-#{Time.now.to_i}"
        params[:chef_json_key] = "#{params[:asg_stack_name]}.json"

        # How should we derive the node attributes dynamically?
        # We should read the structure from the metadata:
        #   Where do the values come from?
        #     Pipeline-scoped values?
        #     Environment-scoped values?

        chef_json = {
          run_list: [ params[:app_name] ],
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
