# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # Auto-generated semantic convention constants.
  module SemanticConventions
  end
end

# TODO: test to make sure the trace and resource constants are present in SemanticCandidates
# TODO: test to make sure the SemanticConventions (stable) constants are all still present in the SemanticCandidates constants
# TODO: remove these convenience requires in the next major version
require_relative 'semantic_conventions/trace'
require_relative 'semantic_conventions/resource'
# TODO: we're not going to add any more convenience requires here; require directly what you use
