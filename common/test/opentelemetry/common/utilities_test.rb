# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::Utilities do
  class OneOffExporter
    def export(spans, timeout: nil); end

    def force_flush(timeout: nil); end

    def shutdown(timeout: nil); end
  end

  let(:common_utils) { OpenTelemetry::Common::Utilities }

  describe '#untraced?' do
    it 'returns true within an untraced block' do
      assert_equal(true, common_utils.untraced { common_utils.untraced? })
    end

    it 'returns false outside an untraced block' do
      common_utils.untraced {}
      assert_equal(false, common_utils.untraced?)
    end

    it 'supports non block format' do
      token = OpenTelemetry::Context.attach(common_utils.untraced)
      assert_equal(true, common_utils.untraced?)
      OpenTelemetry::Context.detach(token)
      assert_equal(false, common_utils.untraced?)
    end
  end

  describe '#utf8_encode' do
    it 'happy path' do
      str = 'pristine ￢'.encode(Encoding::UTF_8)

      assert_equal('pristine ￢', common_utils.utf8_encode(str))

      assert_equal(::Encoding::UTF_8, common_utils.utf8_encode(str).encoding)

      # we don't allocate new objects when a valid UTF-8 string is provided
      assert_same(str, common_utils.utf8_encode(str))
    end

    it 'with invalid conversion' do
      time_bomb = "\xC2".dup.force_encoding(::Encoding::ASCII_8BIT)

      # making sure this is indeed a problem
      assert_raises(Encoding::UndefinedConversionError) do
        time_bomb.encode(Encoding::UTF_8)
      end

      assert_equal(common_utils::STRING_PLACEHOLDER, common_utils.utf8_encode(time_bomb))

      # we can also set a custom placeholder
      assert_equal('?', common_utils.utf8_encode(time_bomb, placeholder: '?'))
    end

    it 'with binary data' do
      byte_array = "keep what\xC2 is valid".dup.force_encoding(::Encoding::ASCII_8BIT)

      assert_equal('keep what is valid', common_utils.utf8_encode(byte_array, binary: true))
    end
  end

  describe '#valid_exporter?' do
    it 'defines exporters via their method signatures' do
      exporter = OneOffExporter.new
      _(common_utils.valid_exporter?(exporter)).must_equal true
    end

    it 'is false for other objects' do
      _(common_utils.valid_exporter?({})).must_equal false
    end
  end

  describe '#valid_url?' do
    it 'returns true if it is a valid uri' do
      _(common_utils.valid_url?('http://example.com')).must_equal(true)
    end

    it 'returns false if it is not a valid uri' do
      _(common_utils.valid_url?('123:123')).must_equal(false)
    end

    it 'returns false if it is nil' do
      _(common_utils.valid_url?(nil)).must_equal(false)
    end

    it 'returns false if it is an empty string' do
      _(common_utils.valid_url?('')).must_equal(false)
    end
  end

  describe '#config_opt' do
    it 'returns the env var' do
      OpenTelemetry::TestHelpers.with_env('a' => 'b') do
        _(common_utils.config_opt('a', default: 'bar')).must_equal('b')
      end
    end

    it 'returns the first requested env var' do
      OpenTelemetry::TestHelpers.with_env('a' => 'b', 'c' => 'd') do
        _(common_utils.config_opt('a', 'b', default: 'bar')).must_equal('b')
      end
    end

    it 'returns the second requested env var if the first is not set' do
      OpenTelemetry::TestHelpers.with_env('c' => 'd') do
        _(common_utils.config_opt('a', 'c', default: 'bar')).must_equal('d')
      end
    end

    it 'returns the default value when no env var is set' do
      _(common_utils.config_opt('a', 'b', default: 'foo')).must_equal('foo')
    end
  end
end
