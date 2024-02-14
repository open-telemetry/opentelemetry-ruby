# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ipsa'

class LinkedListContext
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__linked_list_context_storage__

  class Token
    attr_reader :context, :next_token
    def initialize(context, next_token)
      @context = context
      @next_token = next_token
    end
  end

  private_constant :EMPTY_ENTRIES, :STACK_KEY, :Token

  DetachError = Class.new(StandardError)

  class << self
    def current
      Thread.current[STACK_KEY]&.context || ROOT
    end

    def attach(context)
      next_token = Thread.current[STACK_KEY]
      token = Token.new(context, next_token)
      Thread.current[STACK_KEY] = token
      token
    end

    def detach(token)
      current = Thread.current[STACK_KEY]
      calls_matched = (token == current)
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

      Thread.current[STACK_KEY] = current&.next_token
      calls_matched
    end

    def with_current(ctx)
      token = attach(ctx)
      yield ctx
    ensure
      detach(token)
    end

    def with_value(key, value)
      ctx = current.set_value(key, value)
      token = attach(ctx)
      yield ctx, value
    ensure
      detach(token)
    end

    def with_values(values)
      ctx = current.set_values(values)
      token = attach(ctx)
      yield ctx, values
    ensure
      detach(token)
    end
    def value(key)
      current.value(key)
    end

    def clear
      Thread.current[STACK_KEY] = nil
    end

    def empty
      new(EMPTY_ENTRIES)
    end
  end

  def initialize(entries)
    @entries = entries.freeze
  end

  def value(key)
    @entries[key]
  end

  alias [] value

  def set_value(key, value)
    new_entries = @entries.dup
    new_entries[key] = value
    LinkedListContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    LinkedListContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

class ArrayContext
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__array_context_storage__
  private_constant :EMPTY_ENTRIES, :STACK_KEY

  DetachError = Class.new(StandardError)

  class << self
    def current
      stack.last || ROOT
    end

    def attach(context)
      s = stack
      s.push(context)
      s.size
    end

    def detach(token)
      s = stack
      calls_matched = (token == s.size)
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

      s.pop
      calls_matched
    end

    def with_current(ctx)
      token = attach(ctx)
      yield ctx
    ensure
      detach(token)
    end

    def with_value(key, value)
      ctx = current.set_value(key, value)
      token = attach(ctx)
      yield ctx, value
    ensure
      detach(token)
    end

    def with_values(values)
      ctx = current.set_values(values)
      token = attach(ctx)
      yield ctx, values
    ensure
      detach(token)
    end

    def value(key)
      current.value(key)
    end

    def clear
      stack.clear
    end

    def empty
      new(EMPTY_ENTRIES)
    end

    private

    def stack
      Thread.current[STACK_KEY] ||= []
    end
  end

  def initialize(entries)
    @entries = entries.freeze
  end

  def value(key)
    @entries[key]
  end

  alias [] value

  def set_value(key, value)
    new_entries = @entries.dup
    new_entries[key] = value
    ArrayContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    ArrayContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

values = { 'key' => 'value' }
context = LinkedListContext.empty.set_values(values)

Benchmark.ipsa do |x|
  x.report 'linked list with_value' do
    LinkedListContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'array with_value' do
    ArrayContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.compare!
end

Benchmark.ipsa do |x|
  x.report 'linked list with_values' do
    LinkedListContext.with_values(values) { |ctx, values| ctx }
  end

  x.report 'array with_values' do
    ArrayContext.with_values(values) { |ctx, values| ctx }
  end

  x.compare!
end

Benchmark.ipsa do |x|
  x.report 'linked list with_value recursive' do
    LinkedListContext.with_value('key', 'value') do
      LinkedListContext.with_value('key', 'value') do
        LinkedListContext.with_value('key', 'value') do
          LinkedListContext.with_value('key', 'value') do
            LinkedListContext.with_value('key', 'value') do
              LinkedListContext.with_value('key', 'value') do
                LinkedListContext.with_value('key', 'value') do
                  LinkedListContext.with_value('key', 'value') do
                    LinkedListContext.with_value('key', 'value') do
                      LinkedListContext.with_value('key', 'value') do |ctx, value| ctx end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  x.report 'array with_value recursive' do
    ArrayContext.with_value('key', 'value') do
      ArrayContext.with_value('key', 'value') do
        ArrayContext.with_value('key', 'value') do
          ArrayContext.with_value('key', 'value') do
            ArrayContext.with_value('key', 'value') do
              ArrayContext.with_value('key', 'value') do
                ArrayContext.with_value('key', 'value') do
                  ArrayContext.with_value('key', 'value') do
                    ArrayContext.with_value('key', 'value') do
                      ArrayContext.with_value('key', 'value') do |ctx, value| ctx end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  x.compare!
end
