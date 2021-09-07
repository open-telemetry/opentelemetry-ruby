# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::ActionView::Fanout do
  let(:tracer) { OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance.tracer }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:last_span) { spans.last }
  let(:span_subscriber) do
    OpenTelemetry::Instrumentation::ActionView::SpanSubscriber.new(
      name: 'bar.foo',
      tracer: tracer
    )
  end

  before do
    exporter.reset
    ::ActiveSupport::Notifications.notifier = OpenTelemetry::Instrumentation::ActionView::Fanout.new
  end

  it 'sorts span subscribers first' do
    ::ActiveSupport::Notifications.subscribe('bar.foo') do |event|
      # pass
    end
    ::ActiveSupport::Notifications.subscribe('bar.foo', span_subscriber)

    listeners = ::ActiveSupport::Notifications.notifier.listeners_for('bar.foo')
    _(listeners.first.instance_variable_get(:@delegate)).must_equal(span_subscriber)
  end

  it 'traces an event when a span subscriber is used' do
    ::ActiveSupport::Notifications.subscribe('bar.foo', span_subscriber)
    ::ActiveSupport::Notifications.instrument('bar.foo', extra: 'context')

    _(last_span).wont_be_nil
    _(last_span.name).must_equal('foo bar')
    _(last_span.attributes['extra']).must_equal('context')
  end

  it 'does not trace an event by default' do
    ::ActiveSupport::Notifications.subscribe('bar.foo') do
      # pass
    end
    ::ActiveSupport::Notifications.instrument('bar.foo', extra: 'context')
    _(last_span).must_be_nil
  end

  it 'finishes spans even when other subscribers blow up' do
    ::ActiveSupport::Notifications.subscribe('bar.foo', span_subscriber)
    ::ActiveSupport::Notifications.subscribe('bar.foo') { raise 'boom' }

    expect do
      ::ActiveSupport::Notifications.instrument('bar.foo', extra: 'context')
    end.must_raise RuntimeError

    _(last_span).wont_be_nil
    _(last_span.name).must_equal('foo bar')
    _(last_span.attributes['extra']).must_equal('context')
  end

  describe 'delegate wrapper' do
    it 'keeps existing subscriptions intact' do
      exporter.reset
      ::ActiveSupport::Notifications.notifier = ActiveSupport::Notifications::Fanout.new

      notification_fired = false
      ActiveSupport::Notifications.subscribe('render') do |*_args|
        notification_fired = true
      end

      ::ActiveSupport::Notifications.notifier = OpenTelemetry::Instrumentation::ActionView::Fanout.new(::ActiveSupport::Notifications.notifier)
      ::ActiveSupport::Notifications.subscribe('render', span_subscriber)

      ActiveSupport::Notifications.instrument('render', extra: :information)

      _(last_span).wont_be_nil
      _(last_span.name).must_equal('foo bar')
      _(notification_fired).must_equal(true)
    end
  end
end
