# Metrics API Benchmarks

This directory contains [benchmark-ips](https://github.com/evanphx/benchmark-ips) benchmarks for the OpenTelemetry Ruby Metrics API and SDK. They cover no-op API recording, SDK instrument recording, attribute cardinality, views, exemplar filters, exemplar reservoirs, and aggregations.

## Running the Benchmarks

Run from the `metrics_api/` directory, adding each sibling gem's `lib/` to the load path:

```bash
bundle exec ruby benchmarks/aggregation_bench.rb
bundle exec ruby benchmarks/attributes_bench.rb
bundle exec ruby benchmarks/exemplar_filter_bench.rb
bundle exec ruby benchmarks/exemplar_reservoir_bench.rb
bundle exec ruby benchmarks/instrument_bench.rb
bundle exec ruby benchmarks/noop_instrument_bench.rb
bundle exec ruby benchmarks/view_bench.rb
```

## Benchmark Files

| File | What it measures |
| ---- | --------------- |
| `instrument_bench.rb` | Real SDK instruments — all synchronous types (counter, histogram, gauge, up-down counter) |
| `noop_instrument_bench.rb` | No-op API instruments only — micro-benchmark of the lightest possible instrumentation layer |
| `attributes_bench.rb` | How attribute set size (0 / 1 / 3 / 8 keys) affects SDK counter throughput |
| `view_bench.rb` | Impact of zero, one matching, one non-matching, and three matching registered views |
| `exemplar_filter_bench.rb` | Exemplar filter cost (`AlwaysOff` / `AlwaysOn` / `TraceBased`) on SDK counter |
| `exemplar_reservoir_bench.rb` | Exemplar reservoir cost (`Noop` / `SimpleFixedSize` / `AlignedHistogramBucket`) with `AlwaysOn` filter |
| `aggregation_bench.rb` | Histogram recording throughput across all five aggregations (`Drop`, `Sum`, `LastValue`, `ExplicitBucketHistogram`, `ExponentialBucketHistogram`) |
