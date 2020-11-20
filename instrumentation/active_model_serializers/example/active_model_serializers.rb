# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveModelSerializers'
end

class TestModel < ActiveModelSerializers::Model
  attr_accessor :name
end

class TestModelSerializer < ActiveModel::Serializer
  attributes :name
end

model = TestModel.new(name: 'test object')

ActiveModelSerializers::SerializableResource.new(model).serializable_hash
