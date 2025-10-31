# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'socket'
require 'openssl'

describe OpenTelemetry::SDK::Trace::Export do
  let(:export_module) { OpenTelemetry::SDK::Trace::Export }

  describe 'ExportResult' do
    describe 'initialization' do
      it 'creates a result with just a code' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        _(result.code).must_equal export_module::SUCCESS
        _(result.error).must_be_nil
        _(result.message).must_be_nil
      end

      it 'creates a result with code and message' do
        result = export_module::ExportResult.new(
          export_module::FAILURE,
          message: 'connection refused'
        )
        _(result.code).must_equal export_module::FAILURE
        _(result.error).must_be_nil
        _(result.message).must_equal 'connection refused'
      end

      it 'creates a result with code and error' do
        error = StandardError.new('test error')
        result = export_module::ExportResult.new(
          export_module::FAILURE,
          error: error
        )
        _(result.code).must_equal export_module::FAILURE
        _(result.error).must_equal error
        _(result.message).must_be_nil
      end

      it 'creates a result with code, error, and message' do
        error = StandardError.new('test error')
        result = export_module::ExportResult.new(
          export_module::FAILURE,
          error: error,
          message: 'export failed due to StandardError'
        )
        _(result.code).must_equal export_module::FAILURE
        _(result.error).must_equal error
        _(result.message).must_equal 'export failed due to StandardError'
      end
    end

    describe 'backwards compatibility with integer comparisons' do
      it 'compares equal to SUCCESS constant' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        _(result).must_equal export_module::SUCCESS
        _(result == export_module::SUCCESS).must_equal true
      end

      it 'compares equal to FAILURE constant' do
        result = export_module::ExportResult.new(export_module::FAILURE)
        _(result).must_equal export_module::FAILURE
        _(result == export_module::FAILURE).must_equal true
      end

      it 'compares equal to TIMEOUT constant' do
        result = export_module::ExportResult.new(export_module::TIMEOUT)
        _(result).must_equal export_module::TIMEOUT
        _(result == export_module::TIMEOUT).must_equal true
      end

      it 'does not equal different result codes' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        _(result == export_module::FAILURE).must_equal false
        _(result == export_module::TIMEOUT).must_equal false
      end

      it 'compares with raw integer values' do
        result = export_module::ExportResult.new(0)
        _(result).must_equal 0
        _(result == 0).must_equal true
        _(result == 1).must_equal false
      end
    end

    describe 'ExportResult to ExportResult comparisons' do
      it 'compares equal when codes match' do
        result1 = export_module::ExportResult.new(export_module::SUCCESS)
        result2 = export_module::ExportResult.new(export_module::SUCCESS)
        _(result1).must_equal result2
      end

      it 'compares not equal when codes differ' do
        result1 = export_module::ExportResult.new(export_module::SUCCESS)
        result2 = export_module::ExportResult.new(export_module::FAILURE)
        _(result1 == result2).must_equal false
      end

      it 'compares only by code, ignoring error and message' do
        error1 = StandardError.new('error 1')
        error2 = RuntimeError.new('error 2')
        result1 = export_module::ExportResult.new(
          export_module::FAILURE,
          error: error1,
          message: 'message 1'
        )
        result2 = export_module::ExportResult.new(
          export_module::FAILURE,
          error: error2,
          message: 'message 2'
        )
        _(result1).must_equal result2
      end
    end

    describe '#to_i' do
      it 'returns the code as integer' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        _(result.to_i).must_equal export_module::SUCCESS
        _(result.to_i).must_be_kind_of Integer
      end

      it 'works for all result codes' do
        _(export_module::ExportResult.new(export_module::SUCCESS).to_i).must_equal 0
        _(export_module::ExportResult.new(export_module::FAILURE).to_i).must_equal 1
        _(export_module::ExportResult.new(export_module::TIMEOUT).to_i).must_equal 2
      end
    end

    describe '#success?' do
      it 'returns true for SUCCESS code' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        _(result.success?).must_equal true
      end

      it 'returns false for FAILURE code' do
        result = export_module::ExportResult.new(export_module::FAILURE)
        _(result.success?).must_equal false
      end

      it 'returns false for TIMEOUT code' do
        result = export_module::ExportResult.new(export_module::TIMEOUT)
        _(result.success?).must_equal false
      end
    end

    describe '#failure?' do
      it 'returns false for SUCCESS code' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        _(result.failure?).must_equal false
      end

      it 'returns true for FAILURE code' do
        result = export_module::ExportResult.new(export_module::FAILURE)
        _(result.failure?).must_equal true
      end

      it 'returns false for TIMEOUT code' do
        result = export_module::ExportResult.new(export_module::TIMEOUT)
        _(result.failure?).must_equal false
      end
    end

    describe 'usage in case statements' do
      it 'works in case/when statements with integer constants' do
        result = export_module::ExportResult.new(export_module::SUCCESS)
        outcome = case result.to_i
                  when export_module::SUCCESS
                    :success
                  when export_module::FAILURE
                    :failure
                  when export_module::TIMEOUT
                    :timeout
                  else
                    :unknown
                  end
        _(outcome).must_equal :success
      end

      it 'handles failure case' do
        result = export_module::ExportResult.new(export_module::FAILURE, message: 'test')
        outcome = case result.to_i
                  when export_module::SUCCESS
                    :success
                  when export_module::FAILURE
                    :failure
                  when export_module::TIMEOUT
                    :timeout
                  else
                    :unknown
                  end
        _(outcome).must_equal :failure
      end
    end
  end

  describe 'factory methods' do
    describe '.success' do
      it 'creates a SUCCESS result' do
        result = export_module.success
        _(result).must_be_kind_of export_module::ExportResult
        _(result.code).must_equal export_module::SUCCESS
        _(result).must_equal export_module::SUCCESS
        _(result.success?).must_equal true
        _(result.failure?).must_equal false
      end

      it 'has no error or message' do
        result = export_module.success
        _(result.error).must_be_nil
        _(result.message).must_be_nil
      end
    end

    describe '.failure' do
      it 'creates a FAILURE result without arguments' do
        result = export_module.failure
        _(result).must_be_kind_of export_module::ExportResult
        _(result.code).must_equal export_module::FAILURE
        _(result).must_equal export_module::FAILURE
        _(result.success?).must_equal false
        _(result.failure?).must_equal true
      end

      it 'creates a FAILURE result with message' do
        result = export_module.failure(message: 'connection refused')
        _(result).must_equal export_module::FAILURE
        _(result.message).must_equal 'connection refused'
        _(result.error).must_be_nil
      end

      it 'creates a FAILURE result with error' do
        error = SocketError.new('connection refused')
        result = export_module.failure(error: error)
        _(result).must_equal export_module::FAILURE
        _(result.error).must_equal error
        _(result.message).must_be_nil
      end

      it 'creates a FAILURE result with both error and message' do
        error = SocketError.new('connection refused')
        result = export_module.failure(
          error: error,
          message: 'export failed due to SocketError after 3 retries'
        )
        _(result).must_equal export_module::FAILURE
        _(result.error).must_equal error
        _(result.message).must_equal 'export failed due to SocketError after 3 retries'
      end
    end

    describe '.timeout' do
      it 'creates a TIMEOUT result' do
        result = export_module.timeout
        _(result).must_be_kind_of export_module::ExportResult
        _(result.code).must_equal export_module::TIMEOUT
        _(result).must_equal export_module::TIMEOUT
        _(result.success?).must_equal false
        _(result.failure?).must_equal false
      end

      it 'has no error or message' do
        result = export_module.timeout
        _(result.error).must_be_nil
        _(result.message).must_be_nil
      end
    end
  end

  describe 'real-world scenarios' do
    it 'captures socket error details' do
      error = SocketError.new('Connection refused - connect(2) for "localhost" port 4318')
      result = export_module.failure(
        error: error,
        message: "export failed due to SocketError after 3 retries: #{error.message}"
      )

      _(result).must_equal export_module::FAILURE
      _(result.error).must_be_kind_of SocketError
      _(result.message).must_include 'after 3 retries'
      _(result.message).must_include 'Connection refused'
    end

    it 'captures HTTP error details' do
      result = export_module.failure(
        message: 'export failed with HTTP 503 (Service Unavailable) after 5 retries: Backend service is down'
      )

      _(result).must_equal export_module::FAILURE
      _(result.message).must_include '503'
      _(result.message).must_include 'after 5 retries'
      _(result.message).must_include 'Backend service is down'
    end

    it 'captures SSL error details' do
      error = OpenSSL::SSL::SSLError.new('certificate verify failed')
      result = export_module.failure(
        error: error,
        message: 'SSL error in OTLP::Exporter#send_bytes'
      )

      _(result).must_equal export_module::FAILURE
      _(result.error).must_be_kind_of OpenSSL::SSL::SSLError
      _(result.message).must_equal 'SSL error in OTLP::Exporter#send_bytes'
    end

    it 'captures timeout scenario' do
      result = export_module.failure(message: 'timeout exceeded before sending request')

      _(result).must_equal export_module::FAILURE
      _(result.message).must_equal 'timeout exceeded before sending request'
      _(result.error).must_be_nil
    end

    it 'captures shutdown scenario' do
      result = export_module.failure(message: 'exporter is shutdown')

      _(result).must_equal export_module::FAILURE
      _(result.message).must_equal 'exporter is shutdown'
      _(result.error).must_be_nil
    end
  end

  describe 'legacy code compatibility' do
    # These tests demonstrate that existing code patterns still work

    it 'works with direct constant comparison' do
      result = export_module.success
      if result == export_module::SUCCESS
        outcome = :ok
      else
        outcome = :not_ok
      end
      _(outcome).must_equal :ok
    end

    it 'works with negated comparison' do
      result = export_module.failure
      if result != export_module::SUCCESS
        outcome = :not_success
      else
        outcome = :success
      end
      _(outcome).must_equal :not_success
    end

    it 'works with return value checks' do
      # Simulating existing exporter code
      def mock_export_old_style
        export_module::SUCCESS
      end

      def mock_export_new_style
        export_module.success
      end

      _(mock_export_old_style).must_equal export_module::SUCCESS
      _(mock_export_new_style).must_equal export_module::SUCCESS
      _(mock_export_old_style).must_equal mock_export_new_style
    end

    it 'works in boolean contexts' do
      success_result = export_module.success
      failure_result = export_module.failure

      # These patterns might exist in existing code
      _(success_result == export_module::SUCCESS).must_equal true
      _(failure_result == export_module::SUCCESS).must_equal false
    end
  end

  describe 'error extraction for debugging' do
    it 'allows inspection of failure details' do
      error = RuntimeError.new('unexpected error')
      result = export_module.failure(
        error: error,
        message: 'export failed due to RuntimeError'
      )

      # Code can now check for details
      if result == export_module::FAILURE
        _(result.error).wont_be_nil if result.respond_to?(:error)
        _(result.message).wont_be_nil if result.respond_to?(:message)

        # Access error details for logging
        error_class = result.error.class.name
        error_message = result.error.message
        context_message = result.message

        _(error_class).must_equal 'RuntimeError'
        _(error_message).must_equal 'unexpected error'
        _(context_message).must_equal 'export failed due to RuntimeError'
      end
    end

    it 'handles nil error gracefully' do
      result = export_module.failure(message: 'generic failure')

      if result == export_module::FAILURE
        # Should not raise when error is nil
        _(result.error).must_be_nil
        _(result.message).must_equal 'generic failure'
      end
    end
  end
end

