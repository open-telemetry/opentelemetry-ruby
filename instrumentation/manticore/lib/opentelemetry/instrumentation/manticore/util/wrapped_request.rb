module OpenTelemetry
  module Instrumentation
    module Manticore
      module Util
        # A Class that for protecting direct access to the original Manticore::Response::request object
        #   that has not yet made an outgoing network call yet.
        class WrappedRequest
          def initialize(request)
            @request = request
          end

          # headers related exposure
          def [](key)
            _, value = @request.headers.find { |k, _| k.casecmp(key).zero? }
            value
          end

          def set(key, value)
            @request.set_header(key, value)
          end

          def []=(key, value)
            @request.set_header(key, value)
          end

          def headers
            @request.headers
          end

          def keys
            @request.headers.keys
          end

          def uri
            @request.uri.to_s
          end

          def method
            @request.method
          end

          def host
            self['Host']
          end
        end
      end
    end
  end
end

