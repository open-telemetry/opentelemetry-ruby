# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SemConv do
  OpenTelemetry::SemConv
    .constants
    .reject { |const| const == :Incubating }
    .each do |root_namespace|
      describe "#{root_namespace} stable constants still exist in SemConv::Incubating" do
        OpenTelemetry::SemConv
          .const_get(root_namespace)
          .constants
          .each do |stable_const|
            it stable_const.to_s do
              candidate_namespace = OpenTelemetry::SemConv::Incubating.const_get(root_namespace)
              assert_includes candidate_namespace.constants, stable_const, "Missing stable constant in incubating: #{stable_const}"
            end
          end
      end
    end
end
