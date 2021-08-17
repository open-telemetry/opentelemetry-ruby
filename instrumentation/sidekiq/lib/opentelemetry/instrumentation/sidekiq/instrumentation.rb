# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      # The Instrumentation class contains logic to detect and install the Sidekiq
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('4.2.10')

        install do |_config|
          require_dependencies
          add_client_middleware
          add_server_middleware
          patch_on_startup
        end

        present do
          defined?(::Sidekiq)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :span_naming,                 default: :queue, validate: ->(opt) { %I[job_class queue].include?(opt) }
        option :propagation_style,           default: :link,  validate: ->(opt) { %i[link child none].include?(opt) }
        option :trace_launcher_heartbeat,    default: false, validate: :boolean
        option :trace_poller_enqueue,        default: false, validate: :boolean
        option :trace_poller_wait,           default: false, validate: :boolean
        option :trace_processor_process_one, default: false, validate: :boolean
        option :peer_service,                default: nil,   validate: :string

        private

        def gem_version
          Gem.loaded_specs['sidekiq'].version
        end

        def require_dependencies
          require_relative 'middlewares/client/tracer_middleware'
          require_relative 'middlewares/server/tracer_middleware'

          require_relative 'patches/processor'
          require_relative 'patches/launcher'
          require_relative 'patches/poller'
        end

        def patch_on_startup
          ::Sidekiq.configure_server do |config|
            config.on(:startup) do
              ::Sidekiq::Processor.prepend(Patches::Processor)
              ::Sidekiq::Launcher.prepend(Patches::Launcher)
              ::Sidekiq::Scheduled::Poller.prepend(Patches::Poller)
            end

            config.on(:shutdown) do
              OpenTelemetry.tracer_provider.shutdown
            end
          end
        end

        def add_client_middleware
          ::Sidekiq.configure_client do |config|
            config.client_middleware do |chain|
              chain.add Middlewares::Client::TracerMiddleware
            end
          end
        end

        def add_server_middleware
          ::Sidekiq.configure_server do |config|
            config.client_middleware do |chain|
              chain.add Middlewares::Client::TracerMiddleware
            end
            config.server_middleware do |chain|
              chain.add Middlewares::Server::TracerMiddleware
            end
          end

          if defined?(::Sidekiq::Testing) # rubocop:disable Style/GuardClause
            ::Sidekiq::Testing.server_middleware do |chain|
              chain.add Middlewares::Server::TracerMiddleware
            end
          end
        end
      end
    end
  end
end
