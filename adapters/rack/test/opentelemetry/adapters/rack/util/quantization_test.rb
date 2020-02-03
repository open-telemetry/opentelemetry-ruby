# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/adapters/rack/util/quantization'

describe OpenTelemetry::Adapters::Rack::Util::Quantization do
  let(:described_class) { OpenTelemetry::Adapters::Rack::Util::Quantization }

  describe '#url' do
    let(:result) { described_class.url(url, options) }
    let(:options) { {} }

    describe 'given a URL' do
      let(:url) { 'http://example.com/path?category_id=1&sort_by=asc#featured' }

      describe 'default behavior' do
        it { _(result).must_equal('http://example.com/path?category_id&sort_by') }
      end

      describe 'default behavior for an array' do
        let(:url) { 'http://example.com/path?categories[]=1&categories[]=2' }
        it { _(result).must_equal('http://example.com/path?categories[]') }
      end

      describe 'with query: show: value' do
        let(:options) { { query: { show: ['category_id'] } } }
        it { _(result).must_equal('http://example.com/path?category_id=1&sort_by') }
      end

      describe 'with query: show: :all' do
        let(:options) { { query: { show: :all } } }
        it { _(result).must_equal('http://example.com/path?category_id=1&sort_by=asc') }
      end

      describe 'with query: exclude: value' do
        let(:options) { { query: { exclude: ['sort_by'] } } }
        it { _(result).must_equal('http://example.com/path?category_id') }
      end

      describe 'with query: exclude: :all' do
        let(:options) { { query: { exclude: :all } } }
        it { _(result).must_equal('http://example.com/path') }
      end

      describe 'with show: :all' do
        let(:options) { { fragment: :show } }
        it { _(result).must_equal('http://example.com/path?category_id&sort_by#featured') }
      end

      describe 'with Unicode characters' do
        # URLs do not permit unencoded non-ASCII characters in the URL.
        let(:url) { 'http://example.com/path?繋がってて' }
        it { _(result).must_equal(described_class::PLACEHOLDER) }
      end
    end
  end

  describe '#query' do
    let(:result) { described_class.query(query, options) }

    describe 'given a query' do
      describe 'and no options' do
        let(:options) { {} }

        describe 'with a single parameter' do
          let(:query) { 'foo=foo' }
          it { _(result).must_equal('foo') }

          describe 'with an invalid byte sequence' do
            # \255 is off-limits https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
            # There isn't a graceful way to handle this without stripping interesting
            # characters out either; so just raise an error and default to the placeholder.
            let(:query) { "foo\255=foo" }
            it { _(result).must_equal('?') }
          end
        end

        describe 'with multiple parameters' do
          let(:query) { 'foo=foo&bar=bar' }
          it { _(result).must_equal('foo&bar') }
        end

        describe 'with array-style parameters' do
          let(:query) { 'foo[]=bar&foo[]=baz' }
          it { _(result).must_equal('foo[]') }
        end

        describe 'with semi-colon style parameters' do
          let(:query) { 'foo;bar' }
          # Notice semicolons aren't preseved... no great way of handling this.
          # Semicolons are illegal as of 2014... so this is an edge case.
          # See https://www.w3.org/TR/2014/REC-html5-20141028/forms.html#url-encoded-form-data
          it { _(result).must_equal('foo;bar') }
        end

        describe 'with object-style parameters' do
          let(:query) { 'user[id]=1&user[name]=Nathan' }
          it { _(result).must_equal('user[id]&user[name]') }

          describe 'that are complex' do
            let(:query) { 'users[][id]=1&users[][name]=Nathan&users[][id]=2&users[][name]=Emma' }
            it { _(result).must_equal('users[][id]&users[][name]') }
          end
        end
      end

      describe 'and a show: :all option' do
        let(:query) { 'foo=foo&bar=bar' }
        let(:options) { { show: :all } }
        it { _(result).must_equal(query) }
      end

      describe 'and a show option' do
        describe 'with a single parameter' do
          let(:query) { 'foo=foo' }
          let(:key) { 'foo' }
          let(:options) { { show: [key] } }
          it { _(result).must_equal('foo=foo') }

          describe 'that has a Unicode key' do
            let(:query) { '繋=foo' }
            let(:key) { '繋' }
            it { _(result).must_equal('繋=foo') }

            describe 'that is encoded' do
              let(:query) { '%E7%B9%8B=foo' }
              let(:key) { '%E7%B9%8B' }
              it { _(result).must_equal('%E7%B9%8B=foo') }
            end
          end

          describe 'that has a Unicode value' do
            let(:query) { 'foo=繋' }
            let(:key) { 'foo' }
            it { _(result).must_equal('foo=繋') }

            describe 'that is encoded' do
              let(:query) { 'foo=%E7%B9%8B' }
              it { _(result).must_equal('foo=%E7%B9%8B') }
            end
          end

          describe 'that has a Unicode key and value' do
            let(:query) { '繋=繋' }
            let(:key) { '繋' }
            it { _(result).must_equal('繋=繋') }

            describe 'that is encoded' do
              let(:query) { '%E7%B9%8B=%E7%B9%8B' }
              let(:key) { '%E7%B9%8B' }
              it { _(result).must_equal('%E7%B9%8B=%E7%B9%8B') }
            end
          end
        end

        describe 'with multiple parameters' do
          let(:query) { 'foo=foo&bar=bar' }
          let(:options) { { show: ['foo'] } }
          it { _(result).must_equal('foo=foo&bar') }
        end

        describe 'with array-style parameters' do
          let(:query) { 'foo[]=bar&foo[]=baz' }
          let(:options) { { show: ['foo[]'] } }
          it { _(result).must_equal('foo[]=bar&foo[]=baz') }

          describe 'that contains encoded braces' do
            let(:query) { 'foo[]=%5Bbar%5D&foo[]=%5Bbaz%5D' }
            it { _(result).must_equal('foo[]=%5Bbar%5D&foo[]=%5Bbaz%5D') }

            describe 'that exactly matches the key' do
              let(:query) { 'foo[]=foo%5B%5D&foo[]=foo%5B%5D' }
              it { _(result).must_equal('foo[]=foo%5B%5D&foo[]=foo%5B%5D') }
            end
          end
        end

        describe 'with object-style parameters' do
          let(:query) { 'user[id]=1&user[name]=Nathan' }
          let(:options) { { show: ['user[id]'] } }
          it { _(result).must_equal('user[id]=1&user[name]') }

          describe 'that are complex' do
            let(:query) { 'users[][id]=1&users[][name]=Nathan&users[][id]=2&users[][name]=Emma' }
            let(:options) { { show: ['users[][id]'] } }
            it { _(result).must_equal('users[][id]=1&users[][name]&users[][id]=2') }
          end
        end
      end

      describe 'and an exclude: :all option' do
        let(:query) { 'foo=foo&bar=bar' }
        let(:options) { { exclude: :all } }
        it { _(result).must_equal('') }
      end

      describe 'and an exclude option' do
        describe 'with a single parameter' do
          let(:query) { 'foo=foo' }
          let(:options) { { exclude: ['foo'] } }
          it { _(result).must_equal('') }
        end

        describe 'with multiple parameters' do
          let(:query) { 'foo=foo&bar=bar' }
          let(:options) { { exclude: ['foo'] } }
          it { _(result).must_equal('bar') }
        end

        describe 'with array-style parameters' do
          let(:query) { 'foo[]=bar&foo[]=baz' }
          let(:options) { { exclude: ['foo[]'] } }
          it { _(result).must_equal('') }
        end

        describe 'with object-style parameters' do
          let(:query) { 'user[id]=1&user[name]=Nathan' }
          let(:options) { { exclude: ['user[name]'] } }
          it { _(result).must_equal('user[id]') }

          describe 'that are complex' do
            let(:query) { 'users[][id]=1&users[][name]=Nathan&users[][id]=2&users[][name]=Emma' }
            let(:options) { { exclude: ['users[][name]'] } }
            it { _(result).must_equal('users[][id]') }
          end
        end
      end
    end
  end
end
