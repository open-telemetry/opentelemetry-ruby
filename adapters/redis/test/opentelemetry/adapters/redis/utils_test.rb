# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/redis/utils'

describe OpenTelemetry::Adapters::Redis::Utils do
  let(:utils) { OpenTelemetry::Adapters::Redis::Utils }

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
  end

  describe '#utf8_encode' do
    it 'happy path' do
      str = 'pristine ￢'.encode(Encoding::UTF_8)

      assert_equal('pristine ￢', utils.utf8_encode(str))

      assert_equal(::Encoding::UTF_8, utils.utf8_encode(str).encoding)

      # we don't allocate new objects when a valid UTF-8 string is provided
      assert_same(str, utils.utf8_encode(str))
    end

    it 'with invalid conversion' do
      time_bomb = "\xC2".dup.force_encoding(::Encoding::ASCII_8BIT)

      # making sure this is indeed a problem
      assert_raises(Encoding::UndefinedConversionError) do
        time_bomb.encode(Encoding::UTF_8)
      end

      assert_equal(utils::STRING_PLACEHOLDER, utils.utf8_encode(time_bomb))

      # we can also set a custom placeholder
      assert_equal('?', utils.utf8_encode(time_bomb, placeholder: '?'))
    end

    it 'with binardy data' do
      byte_array = "keep what\xC2 is valid".dup.force_encoding(::Encoding::ASCII_8BIT)

      assert_equal('keep what is valid', utils.utf8_encode(byte_array, binary: true))
    end
  end
end
