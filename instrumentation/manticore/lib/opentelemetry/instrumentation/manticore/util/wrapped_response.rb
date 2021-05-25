module OpenTelemetry
  module Instrumentation
    module Manticore
      module Util
        # A Class that for protecting direct access to the original Manticore::Response object that
        #   represents a response object as already been completed
        class WrappedResponse
          def initialize(response)
            raise ArgumentError, 'expected a http response but received nil' if response.nil?

            @wrapped_response = response
            @headers = response.headers
          end

          def [](key)
            _, value = @headers.find { |k, _| k.casecmp(key).zero? }
            value
          end

          def headers
            @headers
          end

          def status_code
            @wrapped_response.code
          end

          def status_text
            @wrapped_response.message
          end

        end
      end
    end
  end
end

