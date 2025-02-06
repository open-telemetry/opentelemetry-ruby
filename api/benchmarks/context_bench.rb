# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ipsa'
require 'concurrent-ruby'
require 'opentelemetry'

class FiberLocalVarContext
  EMPTY_ENTRIES = {}.freeze
  VAR = Concurrent::FiberLocalVar.new { [] }
  private_constant :EMPTY_ENTRIES, :VAR

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
      VAR.value
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
    FiberLocalVarContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    FiberLocalVarContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

Fiber.attr_accessor :opentelemetry_context

class FiberAttributeContext
  EMPTY_ENTRIES = {}.freeze
  private_constant :EMPTY_ENTRIES

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
      Fiber.current.opentelemetry_context ||= []
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
    FiberAttributeContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    FiberAttributeContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

class LinkedListContext
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__linked_list_context_storage__

  class Token
    def initialize(context, next_token)
      @context = context
      @next_token = next_token
    end

    def context = @context
    def next_token = @next_token
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

class FiberLocalLinkedListContext < Hash
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__fiber_local_linked_list_context_storage__

  class Token
    def initialize(context, next_token)
      @context = context
      @next_token = next_token
    end

    def context = @context
    def next_token = @next_token
  end

  private_constant :EMPTY_ENTRIES, :STACK_KEY, :Token

  DetachError = Class.new(StandardError)

  class << self
    def current
      Fiber[STACK_KEY]&.context || ROOT
    end

    def attach(context)
      Fiber[STACK_KEY] = Token.new(context, Fiber[STACK_KEY])
    end

    def detach(token)
      current = Fiber[STACK_KEY]
      calls_matched = (token == current)
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

      Fiber[STACK_KEY] = current&.next_token
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
      Fiber[STACK_KEY] = nil
    end

    def empty
      new(EMPTY_ENTRIES)
    end
  end

  def initialize(entries)
    super.merge!(entries)
  end

  alias value []

  def set_value(key, value)
    new_entries = dup
    new_entries[key] = value
    new_entries
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    merge(values)
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

class FiberLocalArrayContext
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__fiber_local_array_context_storage__

  # NOTE: This is cool, but is isn't safe for concurrent use because it allows the
  # owner to modify the stack after it has been shared with another fiber.
  class Stack < Array
    def self.current
      s = Fiber[STACK_KEY] ||= new
      s.correct_owner!
    end

    def initialize
      super
      @owner = Fiber.current
    end

    def correct_owner!
      if @owner != Fiber.current
        Fiber[STACK_KEY] = self.class.new.replace(self)
      else
        self
      end
    end
  end

  private_constant :EMPTY_ENTRIES, :STACK_KEY, :Stack

  DetachError = Class.new(StandardError)

  class << self
    def current
      Stack.current.last || ROOT
    end

    def attach(context)
      s = Stack.current
      s.push(context)
      s.size
    end

    def detach(token)
      s = Stack.current
      calls_matched = (token == s.size)
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

      s.pop
      calls_matched
    end

    def with_current(ctx)
      s = Stack.current
      s.push(ctx)
      token = s.size
      yield ctx
    ensure
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless token == s.size
      s.pop
    end

    def with_value(key, value)
      s = Stack.current
      ctx = (s.last || ROOT).set_value(key, value)
      s.push(ctx)
      token = s.size
      yield ctx, value
    ensure
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless token == s.size
      s.pop
    end

    def with_values(values)
      s = Stack.current
      ctx = (s.last || ROOT).set_values(values)
      s.push(ctx)
      token = s.size
      yield ctx, values
    ensure
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless token == s.size
      s.pop
    end

    def value(key)
      current.value(key)
    end

    def clear
      Stack.current.clear
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
    FiberLocalArrayContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    FiberLocalArrayContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

class ImmutableArrayContext
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__immutable_array_context_storage__
  private_constant :EMPTY_ENTRIES, :STACK_KEY

  DetachError = Class.new(StandardError)

  class << self
    def current
      stack.last || ROOT
    end

    def attach(context)
      new_stack = stack + [context]
      Thread.current[STACK_KEY] = new_stack
      new_stack.size
    end

    def detach(token)
      s = stack
      calls_matched = (token == s.size)
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

      Thread.current[STACK_KEY] = s[...-1] || []
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
    ImmutableArrayContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    ImmutableArrayContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

class FiberLocalImmutableArrayContext
  EMPTY_ENTRIES = {}.freeze
  STACK_KEY = :__fiber_local_immutable_array_context_storage__
  private_constant :EMPTY_ENTRIES, :STACK_KEY

  DetachError = Class.new(StandardError)

  class << self
    def current
      stack.last || ROOT
    end

    def attach(context)
      new_stack = stack + [context]
      Fiber[STACK_KEY] = new_stack
      new_stack.size
    end

    def detach(token)
      s = stack
      calls_matched = (token == s.size)
      OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

      Fiber[STACK_KEY] = s[...-1] || []
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
      Fiber[STACK_KEY] ||= []
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
    FiberLocalImmutableArrayContext.new(new_entries)
  end

  def set_values(values) # rubocop:disable Naming/AccessorMethodName:
    FiberLocalImmutableArrayContext.new(@entries.merge(values))
  end

  ROOT = empty.freeze
end

values = { 'key' => 'value' }
context = LinkedListContext.empty.set_values(values)

Benchmark.ipsa do |x|
  x.report 'FiberAttributeContext.with_value' do
    FiberAttributeContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'LinkedListContext.with_value' do
    LinkedListContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'ArrayContext.with_value' do
    ArrayContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'ImmutableArrayContext.with_value' do
    ImmutableArrayContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'FiberLocalVarContext.with_value' do
    FiberLocalVarContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'FiberLocalLinkedListContext.with_value' do
    FiberLocalLinkedListContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'FiberLocalImmutableArrayContext.with_value' do
    FiberLocalImmutableArrayContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.report 'FiberLocalArrayContext.with_value' do
    FiberLocalArrayContext.with_value('key', 'value') { |ctx, value| ctx }
  end

  x.compare!
end

Benchmark.ipsa do |x|
  x.report 'LinkedListContext.with_value recursive' do
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

  x.report 'ArrayContext.with_value recursive' do
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

  x.report 'ImmutableArrayContext.with_value recursive' do
    ImmutableArrayContext.with_value('key', 'value') do
      ImmutableArrayContext.with_value('key', 'value') do
        ImmutableArrayContext.with_value('key', 'value') do
          ImmutableArrayContext.with_value('key', 'value') do
            ImmutableArrayContext.with_value('key', 'value') do
              ImmutableArrayContext.with_value('key', 'value') do
                ImmutableArrayContext.with_value('key', 'value') do
                  ImmutableArrayContext.with_value('key', 'value') do
                    ImmutableArrayContext.with_value('key', 'value') do
                      ImmutableArrayContext.with_value('key', 'value') do |ctx, value| ctx end
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

  x.report 'FiberAttributeContext.with_value recursive' do
    FiberAttributeContext.with_value('key', 'value') do
      FiberAttributeContext.with_value('key', 'value') do
        FiberAttributeContext.with_value('key', 'value') do
          FiberAttributeContext.with_value('key', 'value') do
            FiberAttributeContext.with_value('key', 'value') do
              FiberAttributeContext.with_value('key', 'value') do
                FiberAttributeContext.with_value('key', 'value') do
                  FiberAttributeContext.with_value('key', 'value') do
                    FiberAttributeContext.with_value('key', 'value') do
                      FiberAttributeContext.with_value('key', 'value') do |ctx, value| ctx end
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

  x.report 'FiberLocalVarContext.with_value recursive' do
    FiberLocalVarContext.with_value('key', 'value') do
      FiberLocalVarContext.with_value('key', 'value') do
        FiberLocalVarContext.with_value('key', 'value') do
          FiberLocalVarContext.with_value('key', 'value') do
            FiberLocalVarContext.with_value('key', 'value') do
              FiberLocalVarContext.with_value('key', 'value') do
                FiberLocalVarContext.with_value('key', 'value') do
                  FiberLocalVarContext.with_value('key', 'value') do
                    FiberLocalVarContext.with_value('key', 'value') do
                      FiberLocalVarContext.with_value('key', 'value') do |ctx, value| ctx end
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

  x.report 'FiberLocalLinkedListContext.with_value recursive' do
    FiberLocalLinkedListContext.with_value('key', 'value') do
      FiberLocalLinkedListContext.with_value('key', 'value') do
        FiberLocalLinkedListContext.with_value('key', 'value') do
          FiberLocalLinkedListContext.with_value('key', 'value') do
            FiberLocalLinkedListContext.with_value('key', 'value') do
              FiberLocalLinkedListContext.with_value('key', 'value') do
                FiberLocalLinkedListContext.with_value('key', 'value') do
                  FiberLocalLinkedListContext.with_value('key', 'value') do
                    FiberLocalLinkedListContext.with_value('key', 'value') do
                      FiberLocalLinkedListContext.with_value('key', 'value') do |ctx, value| ctx end
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

  x.report 'FiberLocalImmutableArrayContext.with_value recursive' do
    FiberLocalImmutableArrayContext.with_value('key', 'value') do
      FiberLocalImmutableArrayContext.with_value('key', 'value') do
        FiberLocalImmutableArrayContext.with_value('key', 'value') do
          FiberLocalImmutableArrayContext.with_value('key', 'value') do
            FiberLocalImmutableArrayContext.with_value('key', 'value') do
              FiberLocalImmutableArrayContext.with_value('key', 'value') do
                FiberLocalImmutableArrayContext.with_value('key', 'value') do
                  FiberLocalImmutableArrayContext.with_value('key', 'value') do
                    FiberLocalImmutableArrayContext.with_value('key', 'value') do
                      FiberLocalImmutableArrayContext.with_value('key', 'value') do |ctx, value| ctx end
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

  x.report 'FiberLocalArrayContext.with_value recursive' do
    FiberLocalArrayContext.with_value('key', 'value') do
      FiberLocalArrayContext.with_value('key', 'value') do
        FiberLocalArrayContext.with_value('key', 'value') do
          FiberLocalArrayContext.with_value('key', 'value') do
            FiberLocalArrayContext.with_value('key', 'value') do
              FiberLocalArrayContext.with_value('key', 'value') do
                FiberLocalArrayContext.with_value('key', 'value') do
                  FiberLocalArrayContext.with_value('key', 'value') do
                    FiberLocalArrayContext.with_value('key', 'value') do
                      FiberLocalArrayContext.with_value('key', 'value') do |ctx, value| ctx end
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
