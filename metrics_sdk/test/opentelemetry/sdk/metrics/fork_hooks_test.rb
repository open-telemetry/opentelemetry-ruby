# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-exporter-otlp-metrics' unless RUBY_ENGINE == 'jruby'

describe OpenTelemetry::SDK::Metrics::ForkHooks do
  def fork_with_fork_hooks(before_fork_lambda, after_fork_lambda)
    with_pipe do |inner_read_io, inner_write_io|
      child_pid = fork do # fork twice to avoid prepending fork in the parent process
        setup_fork_hooks(before_fork_lambda, after_fork_lambda) do
          grandchild_pid = fork {}
          Process.waitpid(grandchild_pid)
          inner_write_io.puts grandchild_pid
        end
      end
      Process.waitpid(child_pid)
      grandchild_pid = inner_read_io.gets.chomp.to_i
      refute_equal(child_pid, Process.pid)
      refute_equal(child_pid, grandchild_pid)
      [child_pid, grandchild_pid]
    end
  end

  def setup_fork_hooks(before_hook, after_hook)
    OpenTelemetry::SDK::Metrics::ForkHooks.stub(:before_fork, before_hook) do
      OpenTelemetry::SDK::Metrics::ForkHooks.stub(:after_fork, after_hook) do
        Process.singleton_class.prepend(OpenTelemetry::SDK::Metrics::ForkHooks)
        yield if block_given?
      end
    end
  end

  def with_pipe
    read_io, write_io = IO.pipe
    yield(read_io, write_io)
  ensure
    read_io.close unless read_io.closed?
    write_io.close unless write_io.closed?
  end

  it 'runs the before_hook before forking' do
    with_pipe do |inner_read_io, inner_write_io|
      before_fork_lambda = proc do
        inner_write_io.puts "before_fork was called on #{Process.pid}"
      end
      after_fork_lambda = proc {}
      forking_pid, _forked_pid = fork_with_fork_hooks(before_fork_lambda, after_fork_lambda)

      before_fork_message = inner_read_io.gets.chomp
      assert_equal(before_fork_message, "before_fork was called on #{forking_pid}")
    end
  end

  it 'runs the after_hook after forking' do
    with_pipe do |after_fork_read_io, after_fork_write_io|
      before_fork_lambda = proc {}
      after_fork_lambda = proc do
        after_fork_write_io.puts Process.pid
      end

      forking_pid, forked_pid = fork_with_fork_hooks(before_fork_lambda, after_fork_lambda)
      pid_from_after_fork = after_fork_read_io.gets.chomp.to_i

      refute_equal(pid_from_after_fork, Process.pid)
      refute_equal(pid_from_after_fork, forking_pid)
      assert_equal(forked_pid, pid_from_after_fork)
    end
  end

  it 'calls before_fork on metric readers' do
    reader1 = Class.new do
      attr_reader :before_fork_called

      def before_fork
        @before_fork_called = true
      end
    end.new

    reader2 = OpenStruct.new

    meter_provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
    meter_provider.add_metric_reader(reader1)
    meter_provider.add_metric_reader(reader2)
    ::OpenTelemetry.stub(:meter_provider, meter_provider) do
      OpenTelemetry::SDK::Metrics::ForkHooks.before_fork
    end
    assert(reader1.before_fork_called)
  end

  it 'calls after_fork on metric readers' do
    reader1 = Class.new do
      attr_reader :after_fork_called

      def after_fork
        @after_fork_called = true
      end
    end.new

    reader2 = OpenStruct.new

    meter_provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
    meter_provider.add_metric_reader(reader1)
    meter_provider.add_metric_reader(reader2)
    ::OpenTelemetry.stub(:meter_provider, meter_provider) do
      OpenTelemetry::SDK::Metrics::ForkHooks.after_fork
    end
    assert(reader1.after_fork_called)
  end
end
