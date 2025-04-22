# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

OLD_SEMCONV_ROOTS = %i[Resource Trace].freeze

describe OpenTelemetry::SemanticConventions do
  OpenTelemetry::SemanticConventions
    .constants
    .reject { |const| const == :VERSION }
    .reject { |root_namespace| OLD_SEMCONV_ROOTS.include?(root_namespace) }
    .each do |root_namespace|
      describe "#{root_namespace} stable constants still exist in SemanticCandidates" do
        OpenTelemetry::SemanticConventions
          .const_get(root_namespace)
          .constants
          .each do |stable_const|
            it stable_const.to_s do
              candidate_namespace = OpenTelemetry::SemanticCandidates.const_get(root_namespace)
              assert candidate_namespace.constants.include?(stable_const), "Missing stable constant in candidates: #{stable_const}"
            end
          end
      end
    end
end
