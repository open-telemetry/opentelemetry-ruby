# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      # The Instrumentation class contains logic to detect and install the
      # KafkaRuby instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_patches
          patch

          if defined?(::ActiveSupport::Notifications)
            require_events
            subscribe
          else
            OpenTelemetry.logger.warn('OpenTelemetry::Instrumentation::RubyKafka requires ActiveSupport::Notifications to generate spans from the ruby-kafka instrumentation.')
          end
        end

        present do
          defined?(::Kafka)
        end

        private

        def require_patches
          require_relative 'patches/producer'
          require_relative 'patches/consumer'
          require_relative 'patches/client'
        end

        def patch
          ::Kafka::Producer.prepend(Patches::Producer)
          ::Kafka::Consumer.prepend(Patches::Consumer)
          ::Kafka::Client.prepend(Patches::Client)
        end

        def require_events
          require_relative 'events'
        end

        def subscribe(events: Events::ALL)
          events.each(&:subscribe!)
        end
      end
    end
  end
end
