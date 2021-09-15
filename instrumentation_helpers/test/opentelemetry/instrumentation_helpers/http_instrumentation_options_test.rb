# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::InstrumentationHelpers::HTTP::InstrumentationOptions do
    class FakeBaseOptions
      attr_accessor :option_names_called
      @option_names_called = []

      # def initialize
      #   puts 'inittted'
      #   @option_names_called = []
      # end

      def option_names_called
        @option_names_called
      end

      def self.option(name, default:, validate:)
        puts 'do o go' 
        puts self.instance_variables
        @option_names_called << name
        puts @option_names_called
      end
    end

    subject do
      FakeBaseOptions.tap do |klass|
        # self.class should resolve to the described class
        # ala the described_class helper in rspec
        # https://github.com/seattlerb/minitest/issues/526
        klass.include(OpenTelemetry::InstrumentationHelpers::HTTP::InstrumentationOptions)
      end
    end

    it 'adds hide_query_params option if option method is defined' do
      thing = subject.new
      puts 'allrih'
      puts thing.class.instance_variables
      puts 'na'
      assert_includes(thing.option_names_called, 'hide_query_params')
    end
end
