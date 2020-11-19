require 'ddtrace/contrib/patcher'
require 'ddtrace/ext/app_types'
require 'ddtrace/contrib/active_model_serializers/ext'
require 'ddtrace/contrib/active_model_serializers/events'

module Datadog
  module Contrib
    module ActiveModelSerializers
      # Patcher enables patching of 'active_model_serializers' module.
      module Patcher
        include Contrib::Patcher

        module_function

        def target_version
          Integration.version
        end

        def patch
          Events::Render.subscribe!
        end
      end
    end
  end
end
