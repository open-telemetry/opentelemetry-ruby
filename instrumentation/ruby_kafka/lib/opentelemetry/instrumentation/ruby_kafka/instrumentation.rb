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
        instrumented_gem "ruby_kafka"

        install do |_config|
          require_patches
          patch
        end

        present do
          !defined?(::Kafka).nil?
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
      end
    end
  end
end
