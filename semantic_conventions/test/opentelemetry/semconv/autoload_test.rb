# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# test_helper eager-requires every file, which would mask autoload, so the
# lazy-loading behaviour is exercised in a clean subprocess.
describe 'OpenTelemetry::SemConv autoload' do
  let(:gem_root) { File.expand_path('../../..', __dir__) }

  it 'lazily exposes stable and incubating namespaces from a single require' do
    script = <<~RUBY
      require 'opentelemetry-semantic_conventions'
      raise 'stable namespace not autoloaded' unless OpenTelemetry::SemConv::HTTP::HTTP_REQUEST_METHOD == 'http.request.method'
      raise 'incubating namespace not autoloaded' unless OpenTelemetry::SemConv::Incubating::GEN_AI::GEN_AI_SYSTEM == 'gen_ai.system'
    RUBY

    lib = File.join(gem_root, 'lib')
    api_lib = File.expand_path('../api/lib', gem_root)
    ok = system(Gem.ruby, "-I#{lib}", "-I#{api_lib}", '-e', script)

    assert ok, 'a single require should lazily load both stable and incubating constants'
  end

  it 'registers an autoload for every generated namespace rollup' do
    manifest = File.read(File.join(gem_root, 'lib', 'opentelemetry', 'semconv.rb'))

    namespaces_in('*.rb').each do |ns|
      assert_includes manifest, "autoload :#{ns.upcase}, 'opentelemetry/semconv/#{ns}'"
    end

    namespaces_in('incubating', '*.rb').each do |ns|
      assert_includes manifest, "autoload :#{ns.upcase}, 'opentelemetry/semconv/incubating/#{ns}'"
    end
  end

  private

  # Namespace basenames of the rollup files matched by +glob+ under the semconv dir.
  def namespaces_in(*glob)
    Dir[File.join(gem_root, 'lib', 'opentelemetry', 'semconv', *glob)].map { |f| File.basename(f, '.rb') }
  end
end
