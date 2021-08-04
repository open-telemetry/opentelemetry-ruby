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
        MINIMUM_VERSION = Gem::Version.new('5.2.0')

        install do |_config|
          OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance.install({})
          OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance.install({})
          OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance.install({})
        end

        present do
          defined?(::Rails)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          Gem.loaded_specs['actionpack'].version
        end
      end
    end
  end
end
