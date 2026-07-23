# frozen_string_literal: true

SimpleCov.finalize_merge false if ENV['SIMPLECOV_FINALIZE_MERGE'] == 'false'
SimpleCov.minimum_coverage line: 85
SimpleCov.minimum_coverage branch: ENV['SIMPLECOV_MINIMUM_BRANCH_COVERAGE'].to_i if ENV['SIMPLECOV_MINIMUM_BRANCH_COVERAGE']
SimpleCov.minimum_coverage line: ENV['SIMPLECOV_MINIMUM_LINE_COVERAGE'].to_i if ENV['SIMPLECOV_MINIMUM_LINE_COVERAGE']
SimpleCov.minimum_coverage method: ENV['SIMPLECOV_MINIMUM_METHOD_COVERAGE'].to_i if ENV['SIMPLECOV_MINIMUM_METHOD_COVERAGE']

SimpleCov.enable_coverage :branch
SimpleCov.enable_coverage :method
