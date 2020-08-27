# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # No op implementation of Baggage::Builder
    class Builder
      def set_value(key, value); end

      def remove_value(key); end

      def clear; end
    end
  end
end
