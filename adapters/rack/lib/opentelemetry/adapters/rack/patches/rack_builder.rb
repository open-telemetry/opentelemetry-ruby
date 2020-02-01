# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rack/builder'

module OpenTelemetry
  module Adapters
    module Rack
      module Patches
        # Allows Rack::Builder to use middleware by default
        module RackBuilder
          def self.prepended(base)
            old_initialize = base.instance_method(:initialize)

            # NOTE: define_method is private in ruby-2.4:
            base.send(:define_method, :initialize) do |*args, &block|
              # pass original args to 'super':
              old_initialize.bind(self).call(args, &block)

              # add tracer middleware to default stack, once:
              use Middlewares::TracerMiddleware if @use.empty?
            end
          end
        end
      end
    end
  end
end

require_relative '../middlewares/tracer_middleware'
