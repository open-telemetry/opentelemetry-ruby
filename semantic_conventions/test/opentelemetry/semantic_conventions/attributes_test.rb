# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

OLD_SEMCONV_ROOTS = %i[Resource Trace].freeze

describe OpenTelemetry::SemanticConventions do
  OLD_SEMCONV_ROOTS
    .each do |old_root|
      describe "old root #{old_root} has a corresponding SemanticCandidates namespace and constant" do
        OpenTelemetry::SemanticConventions
          .const_get(old_root)
          .constants
          .each do |const|
            it "(#{const})" do
              root_namespace = const.to_s.split('_').first
              assert OpenTelemetry::SemanticCandidates.constants.include?(root_namespace.to_sym), "Missing candidate namespace: #{root_namespace}"

              candidate_namespace = OpenTelemetry::SemanticCandidates.const_get(root_namespace.to_sym)
              assert candidate_namespace.constants.include?(const), "Missing candidate constant: #{const}"
            end
          end
      end
    end

  OpenTelemetry::SemanticConventions
    .constants
    .reject { |const| const == :VERSION }
    .reject { |root_namespace| OLD_SEMCONV_ROOTS.include?(root_namespace) }
    .each do |root_namespace|
      describe "stable root (#{root_namespace})" do
        OpenTelemetry::SemanticConventions
          .const_get(root_namespace)
          .constants
          .each do |stable_const|
            it "(#{stable_const})" do
              candidate_namespace = OpenTelemetry::SemanticCandidates.const_get(root_namespace)
              assert candidate_namespace.constants.include?(stable_const), "Missing stable constant in candidates: #{stable_const}"
            end
          end
      end
    end
end
