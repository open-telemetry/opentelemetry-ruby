# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module Rails
      # The Instrumentation class contains logic to detect and install the Rails
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance.install({})
          OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance.install({})
          require_dependencies
          require_railtie
        end

        present do
          defined?(::Rails)
        end

        option :disallowed_notification_payload_keys, default: [], validate: :array
        option :notification_payload_transform, default: nil, validate: :callable

        private

        def require_dependencies
          require_relative 'fanout'
          require_relative 'span_subscriber'
        end

        def require_railtie
          require_relative 'railtie'
        end
      end
    end
  end
end
