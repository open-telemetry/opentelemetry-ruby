# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Config::EnvSubstitution do
  # Environment from the data model specification's substitution examples.
  let(:env) do
    {
      'STRING_VALUE' => 'value',
      'BOOL_VALUE' => 'true',
      'INT_VALUE' => '1',
      'FLOAT_VALUE' => '1.1',
      'HEX_VALUE' => '0xdeadbeef',
      'INVALID_MAP_VALUE' => "value\nkey:value",
      'DO_NOT_REPLACE_ME' => 'Never use this value',
      'REPLACE_ME' => '${DO_NOT_REPLACE_ME}',
      'VALUE_WITH_ESCAPE' => 'value$$',
      'EMPTY_VALUE' => ''
    }
  end

  # Loads +yaml+ as the value of a single key and returns it.
  def load_value(yaml)
    OpenTelemetry::Config::EnvSubstitution.load("key: #{yaml}", env)['key']
  end

  describe '.load' do
    {
      '${STRING_VALUE}' => 'value',
      '${BOOL_VALUE}' => true,
      '${INT_VALUE}' => 1,
      '${FLOAT_VALUE}' => 1.1,
      '${HEX_VALUE}' => 3_735_928_559,
      '"${STRING_VALUE}"' => 'value',
      '"${BOOL_VALUE}"' => 'true',
      '"${INT_VALUE}"' => '1',
      '"${FLOAT_VALUE}"' => '1.1',
      '"${HEX_VALUE}"' => '0xdeadbeef',
      '${env:STRING_VALUE}' => 'value',
      '${INVALID_MAP_VALUE}' => "value\nkey:value",
      'foo ${STRING_VALUE} ${FLOAT_VALUE}' => 'foo value 1.1',
      '${UNDEFINED_KEY}' => nil,
      '${UNDEFINED_KEY:-fallback}' => 'fallback',
      '${EMPTY_VALUE:-fallback}' => 'fallback',
      '${REPLACE_ME}' => '${DO_NOT_REPLACE_ME}',
      '${UNDEFINED_KEY:-${STRING_VALUE}}' => '${STRING_VALUE}',
      '$${STRING_VALUE}' => '${STRING_VALUE}',
      '$$${STRING_VALUE}' => '$value',
      '$$$${STRING_VALUE}' => '$${STRING_VALUE}',
      '$${STRING_VALUE:-fallback}' => '${STRING_VALUE:-fallback}',
      '$${STRING_VALUE:-${STRING_VALUE}}' => '${STRING_VALUE:-value}',
      '${UNDEFINED_KEY:-$${UNDEFINED_KEY}}' => '${UNDEFINED_KEY:-${UNDEFINED_KEY}}',
      '${VALUE_WITH_ESCAPE}' => 'value$$',
      'a $$ b' => 'a $ b',
      'a $ b' => 'a $ b'
    }.each do |input, expected|
      it "resolves key: #{input}" do
        if expected.nil?
          _(load_value(input)).must_be_nil
        else
          _(load_value(input)).must_equal expected
        end
      end
    end

    it 'does not substitute mapping keys' do
      result = OpenTelemetry::Config::EnvSubstitution.load('${STRING_VALUE}: value', env)

      _(result).must_equal('${STRING_VALUE}' => 'value')
    end

    it 'substitutes nested scalars and sequence items' do
      result = OpenTelemetry::Config::EnvSubstitution.load(<<~YAML, env)
        outer:
          inner: ${STRING_VALUE}
          list:
            - ${INT_VALUE}
            - name: ${BOOL_VALUE}
      YAML

      _(result).must_equal('outer' => { 'inner' => 'value', 'list' => [1, { 'name' => true }] })
    end

    it 'raises on an invalid reference' do
      _ { load_value('${STRING_VALUE:?error}') }.must_raise OpenTelemetry::Config::EnvSubstitution::Error
    end

    it 'raises on an invalid variable name' do
      _ { load_value('${1API_KEY}') }.must_raise OpenTelemetry::Config::EnvSubstitution::Error
    end

    it 'raises on an unsupported prefix' do
      _ { load_value('${sys:STRING_VALUE}') }.must_raise OpenTelemetry::Config::EnvSubstitution::Error
    end

    it 'returns nil for an empty document' do
      _(OpenTelemetry::Config::EnvSubstitution.load('', env)).must_be_nil
    end

    it 'rejects tags for classes that are not permitted' do
      _ { OpenTelemetry::Config::EnvSubstitution.load('key: !ruby/object:Object {}', env) }.must_raise Psych::DisallowedClass
    end

    it 'rejects aliases' do
      _ { OpenTelemetry::Config::EnvSubstitution.load("a: &x 1\nb: *x", env) }.must_raise Psych::AliasesNotEnabled
    end
  end
end

describe OpenTelemetry::Config do
  describe '.parse' do
    it 'substitutes environment variables' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        disabled: ${OTEL_TEST_SDK_DISABLED}
      YAML
        ENV['OTEL_TEST_SDK_DISABLED'] = 'true'

        _(OpenTelemetry::Config.parse(path).disabled).must_equal true
      ensure
        ENV.delete('OTEL_TEST_SDK_DISABLED')
      end
    end

    it 'returns nil when a substitution reference is invalid' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        disabled: ${OTEL_TEST_SDK_DISABLED:?error}
      YAML
        _(OpenTelemetry::Config.parse(path)).must_be_nil
      end
    end
  end
end
