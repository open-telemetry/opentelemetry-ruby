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

## Sample Run

### System Specifications

**OS Information:**

- Distribution: Ubuntu 24.04.3 LTS (Noble Numbat)
- Kernel: Linux 6.14.0-1018-aws
- Architecture: x86_64

**Memory:**

- Total: ~3.91 GB (4,006,000 kB)
- Available: ~3.40 GB (3,470,496 kB)
- Free: ~3.13 GB (3,195,972 kB)

**CPU:**

- Processor: Intel(R) Xeon(R) CPU E5-2686 v4 @ 2.30GHz
- Cores: 2
- Threads: 2
- Virtualization: Xen (Full)
- Cache: L1d 64 KiB × 2 | L1i 64 KiB × 2 | L2 512 KiB × 2 | L3 45 MiB

**Runtime:**

- Ruby: 3.4.0dev (2024-12-25 master f450108330) +PRISM [x86_64-linux]

### Benchmark Results

#### Aggregation Benchmarks

`bundle exec ruby benchmarks/aggregation_bench.rb`

| Aggregation Type | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| Sum | 172,228.5 i/s | 5.81 μs/i | **Fastest** |
| Drop | 163,185.4 i/s | 6.13 μs/i | 1.06x slower |
| LastValue | 155,601.6 i/s | 6.43 μs/i | 1.11x slower |
| ExplicitBucketHistogram | 153,229.4 i/s | 6.53 μs/i | 1.12x slower |
| ExponentialBucketHistogram | 83,628.0 i/s | 11.96 μs/i | 2.06x slower |

#### Attribute Cardinality (SDK Counter)

`bundle exec ruby benchmarks/attributes_bench.rb`

| Attribute Count | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| No attrs (0) | 235,949.5 i/s | 4.24 μs/i | **Fastest** |
| Small attrs (1) | 223,849.7 i/s | 4.47 μs/i | 1.05x slower |
| Medium attrs (3) | 216,702.4 i/s | 4.61 μs/i | 1.09x slower |
| Large attrs (8) | 197,824.3 i/s | 5.05 μs/i | 1.19x slower |

#### Exemplar Filters

`bundle exec ruby benchmarks/exemplar_filter_bench.rb`

| Filter Type | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| AlwaysOff | 227,492.0 i/s | 4.40 μs/i | **Fastest** |
| TraceBased | 211,242.6 i/s | 4.73 μs/i | 1.08x slower |
| AlwaysOn | 133,263.6 i/s | 7.50 μs/i | 1.71x slower |

#### Exemplar Reservoirs

`bundle exec ruby benchmarks/exemplar_reservoir_bench.rb`

| Instrument | Reservoir Type | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- | --- |
| Counter | SimpleFixedSize | 126,669.7 i/s | 7.89 μs/i | **Fastest** |
| Histogram | SimpleFixedSize | 118,602.8 i/s | 8.43 μs/i | 1.07x slower |
| Histogram | AlignedHistogramBucket | 113,535.5 i/s | 8.81 μs/i | 1.12x slower |
| Counter | Noop | 25,391.0 i/s | 39.38 μs/i | 4.99x slower |
| Histogram | Noop | 25,329.6 i/s | 39.48 μs/i | 5.00x slower |

#### Synchronous Instruments (SDK)

`bundle exec ruby benchmarks/instrument_bench.rb`

| Instrument | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| up_down_counter#add | 225,684.1 i/s | 4.43 μs/i | **Fastest** |
| counter#add | 222,590.0 i/s | 4.49 μs/i | ~Same |
| gauge#record | 202,016.1 i/s | 4.95 μs/i | 1.12x slower |
| histogram#record | 199,490.0 i/s | 5.01 μs/i | 1.13x slower |

#### No-Op Instruments (API)

`bundle exec ruby benchmarks/noop_instrument_bench.rb`

| Instrument | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| noop up_down_counter#add | 4,342,256.4 i/s | 230.30 ns/i | **Fastest** |
| noop counter#add | 4,334,817.2 i/s | 230.69 ns/i | ~Same |
| noop gauge#record | 4,331,789.5 i/s | 230.85 ns/i | ~Same |
| noop histogram#record | 4,329,196.6 i/s | 230.99 ns/i | ~Same |

#### View Impact on Performance

`bundle exec ruby benchmarks/view_bench.rb`

| Views | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| No views | 225,245.4 i/s | 4.44 μs/i | **Fastest** |
| 1 non-matching | 224,709.9 i/s | 4.45 μs/i | ~Same |
| 1 matching | 169,952.5 i/s | 5.88 μs/i | 1.33x slower |
| 3 matching | 62,762.3 i/s | 15.93 μs/i | 3.59x slower |
