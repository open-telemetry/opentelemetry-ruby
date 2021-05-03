# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/redis/utils'
require_relative '../../../../lib/opentelemetry/instrumentation/redis/instrumentation'

describe OpenTelemetry::Instrumentation::Redis::Utils do
  let(:utils) { OpenTelemetry::Instrumentation::Redis::Utils }
  let(:instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  before do
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(enable_statement_obfuscation: false)
  end

  describe '#format_arg' do
    subject { utils.format_arg(arg) }

    describe 'given' do
      describe 'nil' do
        let(:arg) { nil }
        it { _(subject).must_equal('') }
      end

      describe 'an empty string' do
        let(:arg) { '' }
        it { _(subject).must_equal('') }
      end

      describe 'a string under the limit' do
        let(:arg) { 'HGETALL' }
        it { _(subject).must_equal(arg) }
      end

      describe 'a string up to limit' do
        let(:arg) { 'A' * 50 }
        it { _(subject).must_equal(arg) }
      end

      describe 'a string over the limit by one' do
        let(:arg) { 'B' * 101 }
        it { _(subject).must_equal('B' * 47 + '...') }
      end

      describe 'a string over the limit by a lot' do
        let(:arg) { 'C' * 1000 }
        it { _(subject).must_equal('C' * 47 + '...') }
      end

      describe 'with arg obfuscation' do
        before do
          instrumentation.instance_variable_set(:@installed, false)
          instrumentation.install(enable_statement_obfuscation: true)
        end
        let(:arg) { 'XYZ' }
        it { _(subject).must_equal('?') }
      end

      describe 'an object that can\'t be converted to a string' do
        let(:arg) { object_class.new }
        let(:object_class) do
          Class.new do
            def to_s
              raise "can't make a string of me"
            end
          end
        end
        it { _(subject).must_equal('?') }
      end

      describe 'an invalid byte sequence' do
        # \255 is off-limits https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
        let(:arg) { "SET foo bar\255" }
        it { _(subject).must_equal('SET foo bar') }
      end
    end
  end

  describe '#format_statement' do
    subject { utils.format_statement(args) }

    describe 'given an array' do
      describe 'of some basic values' do
        let(:args) { [:set, 'KEY', 'VALUE'] }
        it { _(subject).must_equal('SET KEY VALUE') }
      end

      describe 'of many very long args (over the limit)' do
        let(:args) { Array.new(20) { 'X' * 90 } }
        it { _(subject.length).must_equal(500) }
        it { _(subject[496..499]).must_equal('X...') }
      end
    end

    describe 'given a nested array' do
      let(:args) { [[:set, 'KEY', 'VALUE']] }
      it { _(subject).must_equal('SET KEY VALUE') }
    end

    describe 'with arg obfuscation' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(enable_statement_obfuscation: true)
      end
      let(:args) { [:set, 'KEY', 'VALUE'] }
      it { _(subject).must_equal('SET ? ?') }
    end
  end
end
