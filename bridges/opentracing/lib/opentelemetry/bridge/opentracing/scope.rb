# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # Scope represents an OpenTracing Scope
      class Scope
        attr_reader :span

        def initialize(manager, span, finish_on_close)
          @manager = manager
          @parent = manager.active
          @span = span
          @finish_on_close = finish_on_close
        end

        def close
          @span.finish if @finish_on_close
          @manager.active = @parent
        end
      end
    end
  end
end
