module Build
  module Commit
    class ExtendedStaticAnalysis < StaticAnalysis
      def initialize(store:)
        # execute base class logic first
        super(store: store)

        # execute custom logic
        execute_jslint(working_directory: store.get(attrib_name: "params")[:working_directory])
      end

      def execute_jslint(working_directory:)
        Dir.chdir(working_directory) do
          puts "Running jslint on #{working_directory}..."
          results = `find . -name "*.js" -print0 | xargs -0 jslint`
          puts results
        end
      end
    end
  end
end
