module OpenTelemetry
  module Instrumentation
    module Manticore
      module Util
        # A Class that for protecting direct access to the original Manticore::Response::request instance object
        #   that has not yet made an outgoing network call yet.
        # Most of the non-headers related methods are exposed to use conveniently and avoid mutating the @request object.
        class WrappedRequest
          # @param [Manticore::Client::Request] request
          def initialize(request)
            raise ArgumentError, 'expected a http request but received nil' if request.nil?
            @request = request
          end

          def set(key, value)
            @request.set_header(key, value)
          end

          # This is required to use the OpenTelemetry.propagation.#inject method
          def []=(key, value)
            @request.set_header(key, value)
          end

          def headers
            @request.headers
          end

          def uri
            @request.uri.to_s
          end

          def method
            @request.method
          end
        end
      end
    end
  end
end

