# frozen_string_literal: true

require 'grpc'

module GRPCTrace
  RPC_SERVICE_KEY = 'rpc.service'
  NET_PEER_IP_KEY = 'net.peer.ip'
  NET_PEER_PORT_KEY = 'net.peer.port'

  MESSAGE_TYPE_KEY = 'message.type'
  MESSAGE_ID_KEY = 'message.id'
  MESSAGE_UNCOMPRESSED_SIZE_KEY = 'message.uncompressed_size'

  module Util
    FULL_METHOD_REGEXP = /^\/?(?:\S+\.)?(\S+)\/\S+$/
    HOST_PORT_REGEXP = /^(?:ipv[46]:)?(?:\[)?([0-9a-f.:]+?)(?:\])?(?::)([0-9]+)$/

    def service_from_full_method(method)
      match = method.match(FULL_METHOD_REGEXP)
      return '' unless match
      match[1]
    end

    def full_method_from_method(method)
      # HACK
      # The GRPC::ActiveCall doesn't contain the original full method name anymore
      # Either this should be fixed on GRPC side or this hack is needed
      "/#{method.owner.service_name}/#{Util.camelcase(method.name.to_s)}"
    end

    def peer_info_from_call(call)
      # HACK
      # The GRPC::ActiveCall::InterceptableView we got here doesn't allow accessing peer info
      # So instead we grab the info from the underlying ActiveCall
      peer = call.instance_variable_get(:@wrapped).peer
      host, port = Util.split_host_port(peer)

      {
        NET_PEER_IP_KEY => host,
        NET_PEER_PORT_KEY => port
      }
    end

    def self.camelcase(s)
      s.sub!(/^[a-z\d]*/) { |match| match.capitalize }
      s.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      s
    end

    def self.split_host_port(peer)
      _, host, port = peer.match(HOST_PORT_REGEXP).to_a
      [host, port]
    end
  end

  class UnaryClientInterceptor < GRPC::ClientInterceptor
    include Util

    def initialize(tracer, options = {})
      super(options)
      @tracer = tracer
    end

    def request_response(request: nil, call: nil, method: nil, metadata: nil)
      puts "Intercepting request response method #{method}" \
        " for request #{request} with call #{call} and metadata: #{metadata}"

      @tracer.in_span(
        method,
        kind: :client,
        attributes: {
          RPC_SERVICE_KEY => service_from_full_method(method)
        }.merge(peer_info_from_call(call))
      ) do |span|
        OpenTelemetry.propagation.http.inject(metadata)

        begin
          span.status = OpenTelemetry::Trace::Status::OK
          yield(request: request, call: call, method: method, metadata: metadata)
        rescue GRPC::BadStatus => e
          span.status = e.code
          raise e
        end
      end
    end
  end

  class UnaryServerInterceptor < GRPC::ServerInterceptor
    include Util

    def initialize(tracer, options = {})
      super(options)
      @tracer = tracer
    end

    def request_response(request: nil, call: nil, method: nil)
      puts "Intercepting request response method #{method}" \
        " for request #{request} from #{call.peer}" \
        " with call #{call} and metadata: #{call.metadata}"

      context = OpenTelemetry.propagation.text.extract(call.metadata)

      full_method = full_method_from_method(method)

      @tracer.in_span(
        full_method,
        kind: :server,
        attributes: {
          RPC_SERVICE_KEY => service_from_full_method(full_method)
        }.merge(peer_info_from_call(call)),
        with_parent_context: context
      ) do |span|
        begin
          span.status = OpenTelemetry::Trace::Status::OK
          yield
        rescue GRPC::BadStatus => e
          span.status = e.code
          raise e
        end
      end
    end
  end
end
