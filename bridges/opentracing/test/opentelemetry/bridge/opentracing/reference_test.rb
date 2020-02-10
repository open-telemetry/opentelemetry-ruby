# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Reference do
  Reference = OpenTelemetry::Bridge::OpenTracing::Reference
  SpanContextBridge = OpenTelemetry::Bridge::OpenTracing::SpanContext
  Link = OpenTelemetry::Trace::Link
  SpanContext = OpenTelemetry::Trace::SpanContext
  describe '#from_link' do
    it 'makes a reference from a link' do
      link = Link.new(SpanContext.new)
      ref = Reference.from_link(link)
      ref.must_be_instance_of OpenTracing::Reference
      ref.context.must_equal link.context
    end
  end
  describe '#to_link' do
    it 'makes a link from a reference' do
      ref = OpenTracing::Reference.new(OpenTracing::SpanContext.new, nil)
      link = Reference.to_link(ref)
      link.must_be_instance_of Link
      link.context.must_equal ref.context
    end
  end

  describe 'invertiblity' do
    it 'to_link should be the inverse of from_link' do
      # we can't do from_link(to_link(blah)) as to_link looses the type
      link = Link.new(SpanContext.new)
      remade = Reference.to_link(Reference.from_link(link))
      link.must_equal remade
    end
  end
end
