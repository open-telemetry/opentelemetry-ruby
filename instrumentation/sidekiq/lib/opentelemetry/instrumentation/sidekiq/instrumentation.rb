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
        install do |_config|
          require_dependencies
          add_client_middleware
          add_server_middleware
          patch_on_startup
        end

        present do
          defined?(::Sidekiq)
        end

        private

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
