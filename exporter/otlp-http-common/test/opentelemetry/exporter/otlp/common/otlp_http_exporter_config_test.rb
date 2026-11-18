# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig do
  describe 'headers:' do
    it 'fails fast when header values are missing' do
      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a = ') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)

      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'a = ') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'fails fast when header or values are not found' do
      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => ',') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)

      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => ',') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'fails fast when header values contain invalid escape characters' do
      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'c=hi%F3') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)

      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'c=hi%F3') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'fails fast when headers are invalid' do
      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'this is not a header') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)

      error = _ do
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'this is not a header') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'restricts explicit headers to a String or Hash' do
      exp = OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(headers: { 'token' => 'über' })
      _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])

      exp = OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(headers: 'token=%C3%BCber')
      _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])

      error = _ do
        exp = OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(headers: Object.new)
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'ignores later mutations of a headers Hash parameter' do
      a_hash_to_mutate_later = { 'token' => 'über' }
      exp = OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(headers: a_hash_to_mutate_later)
      _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])

      a_hash_to_mutate_later['token'] = 'unter'
      a_hash_to_mutate_later['oops'] = 'i forgot to add this, too'
      _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])
    end

    describe 'Headers Environment Variable' do
      it 'allows any number of the equal sign (=) characters in the value' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'a', value: 'b' }, { name: 'c', value: 'd==' }, { name: 'e', value: 'f' }])

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'a', value: 'b' }, { name: 'c', value: 'd==' }, { name: 'e', value: 'f' }])
      end

      it 'trims any leading or trailing whitespaces in keys and values' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'a', value: 'b' }, { name: 'c', value: 'd' }, { name: 'e', value: 'f' }])

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'a', value: 'b' }, { name: 'c', value: 'd' }, { name: 'e', value: 'f' }])
      end

      it 'decodes values as URL encoded UTF-8 strings' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'über', value: 'token' }])

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'über', value: 'token' }])
      end

      it 'prefers TRACES specific variable' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f', 'OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env('TRACES')
        end
        _(exp.instance_variable_get(:@headers)).must_equal([{ name: 'token', value: 'über' }])
      end
    end
  end
end
