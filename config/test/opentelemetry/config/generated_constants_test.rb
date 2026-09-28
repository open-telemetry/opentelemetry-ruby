# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Config::Model do
  struct_classes = OpenTelemetry::Config::Model.constants.filter_map do |const_name|
    klass = OpenTelemetry::Config::Model.const_get(const_name)
    [const_name, klass] if klass.respond_to?(:from_hash)
  end

  describe '.from_hash' do
    struct_classes.each do |const_name, klass|
      it "builds a #{const_name} instance from an empty hash" do
        _(klass.from_hash({})).must_be_kind_of klass
      end

      it "returns nil when given non-hash input for #{const_name}" do
        _(klass.from_hash(nil)).must_be_nil
        _(klass.from_hash('not a hash')).must_be_nil
      end
    end
  end
end
