# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::Utilities do
  let(:common_utils) { OpenTelemetry::Common::Utilities }

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
end
