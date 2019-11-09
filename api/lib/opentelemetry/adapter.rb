# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # The basic interface for Adapter objects
  class Adapter
    class << self
      attr_reader :config

      def install(config = {})
        @config = config
        new.install
      end

      def tracer
        OpenTelemetry.tracer_factory.tracer(config[:name], config[:version])
      end
    end
  end
end
