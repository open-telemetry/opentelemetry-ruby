# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      # The Instrumentation class contains logic to detect and install the Elasticsearch instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        option :create_es_spans, default: true, validate: :boolean
        option :db_statement, default: :include, validate: %I[omit include]
        option :transport_client, default: "Elastic::Transport::Client", validate: :string

        install do |_config|
          require_patches
        end

        present do
          # We're checking for Elastic::API::Common::Client, which delegates a
          # request to a wrapped client. See usage details here: https://github.com/elastic/elasticsearch-ruby/tree/main/elasticsearch-api#usage)
          # and the code here: https://github.com/elastic/elasticsearch-ruby/blob/v8.0.1/elasticsearch-api/lib/elasticsearch/api/namespace/common.rb#L35-L39
          defined?(::Elastic::Transport::Client)
        end

        private

        def require_patches
          require_relative('../patches/client.rb')
          ::Elastic::Transport::Client.prepend(OpenTelemetry::Instrumentation::Elasticsearch::Client)
        end
      end
    end
  end
end
