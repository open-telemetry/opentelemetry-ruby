#frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GRPC
      # The Instrumentation class contains logic to detect and install the GRPC instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(GRPC)
        end

        private

        def require_dependencies
          require_relative './patches/active_call'
          require_relative './patches/bidi_call'
          require_relative './patches/core_call'
          require_relative './patches/client_stub'
          require_relative './patches/rpc_desc'
        end

        def patch_client
          ::GRPC::ActiveCall.prepend(OpenTelemetry::Instrumentation::GRPC::Patches::ActiveCall)
          ::GRPC::BidiCall.prepend(OpenTelemetry::Instrumentation::GRPC::Patches::BidiCall)
          ::GRPC::Core::Call.prepend(OpenTelemetry::Instrumentation::GRPC::Patches::CoreCall)
          ::GRPC::ClientStub.prepend(OpenTelemetry::Instrumentation::GRPC::Patches::ClientStub)
          ::GRPC::RpcDesc.prepend(OpenTelemetry::Instrumentation::GRPC::Patches::RpcDesc)
        end
      end
    end
  end
end
