# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      # The Instrumentation class contains logic to detect and install the Elasticsearch instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::Elasticsearch::Transport)
        end

        private

        def require_dependencies
          require_relative 'patches/client'
        end

        def patch_client
          ::Elasticsearch::Transport::Client.send(:include, Patches::Client)
        end
      end
    end
  end
end
