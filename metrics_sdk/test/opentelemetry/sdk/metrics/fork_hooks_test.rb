# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

return if Gem.win_platform? || %w[jruby truffleruby].include?(RUBY_ENGINE) # forking is not available on these platforms or runtimes

require 'test_helper'
require 'json'

describe OpenTelemetry::SDK::Metrics::ForkHooks do
  def fork_with_fork_hooks(after_fork_lambda)
    with_pipe do |inner_read_io, inner_write_io|
      child_pid = fork do # fork twice to avoid prepending fork in the parent process
        setup_fork_hooks(after_fork_lambda) do
          grandchild_pid = fork {}
          Timeout.timeout(5) { Process.waitpid(grandchild_pid) }
          message = { 'child_pid' => Process.pid, 'grandchild_pid' => grandchild_pid }.to_json
          inner_write_io.puts message
        rescue StandardError => e
          message = { 'error' => e.message }.to_json
          inner_write_io.puts message
        end
      end
      Timeout.timeout(10) { Process.waitpid(child_pid) }
      received_from_child = JSON.parse(inner_read_io.gets.chomp)
      refute_includes(received_from_child, 'error')
      grandchild_pid = received_from_child['grandchild_pid']
      refute_equal(child_pid, Process.pid)
      refute_equal(child_pid, grandchild_pid)
      [child_pid, grandchild_pid]
    end
  end

  def setup_fork_hooks(after_hook)
    OpenTelemetry::SDK::Metrics::ForkHooks.stub(:after_fork, after_hook) do
      Process.singleton_class.prepend(OpenTelemetry::SDK::Metrics::ForkHooks)
      yield if block_given?
    end
  end

  def with_pipe
    read_io, write_io = IO.pipe
    yield(read_io, write_io)
  ensure
    read_io.close unless read_io.closed?
    write_io.close unless write_io.closed?
  end

  it 'runs the after_hook after forking' do
    with_pipe do |after_fork_read_io, after_fork_write_io|
      after_fork_lambda = proc do
        message = { 'after_fork_pid' => Process.pid }.to_json
        after_fork_write_io.puts message
      end

      forking_pid, forked_pid = fork_with_fork_hooks(after_fork_lambda)
      pid_from_after_fork = JSON.parse(after_fork_read_io.gets.chomp)['after_fork_pid'].to_i

      refute_equal(pid_from_after_fork, Process.pid)
      refute_equal(pid_from_after_fork, forking_pid)
      assert_equal(forked_pid, pid_from_after_fork)
    end
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
