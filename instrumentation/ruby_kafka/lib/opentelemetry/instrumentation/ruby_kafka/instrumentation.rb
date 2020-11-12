# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      # The Instrumentation class contains logic to detect and install the
      # KafkaRuby instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
          subscribe
        end

        present do
          defined?(::Kafka)
        end

        private

        def require_dependencies
          require_relative 'patches/producer'
          require_relative 'events'
        end

        def patch
          ::Kafka::Producer.prepend(Patches::Producer)
        end

        def subscribe(events: Events::ALL)
          events.each(&:subscribe!)
        end
      end
    end
  end
end
