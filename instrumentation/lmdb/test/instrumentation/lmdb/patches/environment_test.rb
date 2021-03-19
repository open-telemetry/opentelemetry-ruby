# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/lmdb'
require_relative '../../../../lib/opentelemetry/instrumentation/lmdb/patches/environment'

describe OpenTelemetry::Instrumentation::LMDB::Patches::Environment do
  let(:instrumentation) { OpenTelemetry::Instrumentation::LMDB::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }

  let(:db_path) { File.join(File.dirname(__FILE__), '..', 'tmp', 'test') }
  let(:lmdb) { LMDB.new(db_path) }

  before do
    exporter.reset
    instrumentation.install({})
    FileUtils.rm_rf(db_path)
    FileUtils.mkdir_p(db_path)
  end

  after do
    FileUtils.rm_rf(db_path)
    lmdb.close
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#transaction' do
    it 'traces' do
      lmdb.transaction do
        lmdb.database['foo'] = 'bar'
      end

      _(span.name).must_equal('PUT foo')
      _(span.attributes['db.system']).must_equal 'lmdb'
      _(span.attributes['db.statement']).must_equal 'PUT foo bar'

      _(last_span.name).must_equal('TRANSACTION')
      _(last_span.attributes['db.system']).must_equal 'lmdb'
    end
  end
end
