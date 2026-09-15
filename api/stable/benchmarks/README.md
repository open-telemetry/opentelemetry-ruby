# Trace API Benchmarks

This directory contains [benchmark-ips](https://github.com/evanphx/benchmark-ips) benchmarks for the OpenTelemetry Ruby API and SDK.

## Running the Benchmarks

Run from the `api/` directory:

```bash
# Run all benchmarks
rake bench:all

# Or run individual benchmarks:
bundle exec ruby benchmarks/context_bench.rb
bundle exec ruby benchmarks/id_generation_bench.rb
bundle exec ruby benchmarks/span_bench.rb
bundle exec ruby benchmarks/tracer_bench.rb
```

## Benchmark Files

| File | What it measures |
| ---- | --------------- |
| `context_bench.rb` | Context storage implementations — standard and fiber-local variants with both single and recursive value operations |
| `id_generation_bench.rb` | ID generation performance — trace IDs, span IDs, and random byte generation |
| `span_bench.rb` | Span operations — setting name, attributes, and adding events |
| `tracer_bench.rb` | Span creation performance — basic, with parent context, with attributes, and with links |

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

#### Context Operations

`bundle exec ruby benchmarks/context_bench.rb`

**Standard with_value Operations:**

| Context Type | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| FiberLocalArrayContext.with_value | 756,047.3 i/s | 1.32 μs/i | **Fastest** |
| FiberLocalLinkedListContext.with_value | 689,024.1 i/s | 1.45 μs/i | 1.10x slower |
| FiberAttributeContext.with_value | 651,214.4 i/s | 1.54 μs/i | 1.16x slower |
| ArrayContext.with_value | 633,636.0 i/s | 1.58 μs/i | 1.19x slower |
| LinkedListContext.with_value | 543,032.7 i/s | 1.84 μs/i | 1.39x slower |
| FiberLocalImmutableArrayContext.with_value | 488,004.8 i/s | 2.05 μs/i | 1.55x slower |
| FiberLocalVarContext.with_value | 477,231.8 i/s | 2.10 μs/i | 1.58x slower |
| ImmutableArrayContext.with_value | 473,185.9 i/s | 2.11 μs/i | 1.60x slower |

**Recursive with_value Operations:**

| Context Type | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| FiberLocalArrayContext.with_value | 79,682.3 i/s | 12.55 μs/i | **Fastest** |
| FiberLocalLinkedListContext.with_value | 70,142.6 i/s | 14.26 μs/i | 1.14x slower |
| FiberAttributeContext.with_value | 69,806.8 i/s | 14.33 μs/i | 1.14x slower |
| ArrayContext.with_value | 66,249.2 i/s | 15.09 μs/i | 1.20x slower |
| LinkedListContext.with_value | 57,670.2 i/s | 17.34 μs/i | 1.38x slower |
| FiberLocalVarContext.with_value | 49,221.0 i/s | 20.32 μs/i | 1.62x slower |
| FiberLocalImmutableArrayContext.with_value | 48,464.7 i/s | 20.63 μs/i | 1.64x slower |
| ImmutableArrayContext.with_value | 47,063.2 i/s | 21.25 μs/i | 1.69x slower |

#### ID Generation

`bundle exec ruby benchmarks/id_generation_bench.rb`

**Trace ID Generation:**

| Method | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| generate_trace_id_while | 3,620,066.2 i/s | 276.24 ns/i | **Fastest** |
| generate_trace_id | 2,052,539.5 i/s | 487.20 ns/i | 1.76x slower |

**Span ID Generation:**

| Method | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| generate_span_id_while | 3,797,911.0 i/s | 263.30 ns/i | **Fastest** |
| generate_span_id | 1,963,041.8 i/s | 509.41 ns/i | 1.93x slower |

**Random Bytes Generation:**

| Method | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| generate_r_in_place | 1,712,273.8 i/s | 584.02 ns/i | **Fastest** |
| generate_r | 1,348,496.2 i/s | 741.57 ns/i | 1.27x slower |

#### Span Operations

`bundle exec ruby benchmarks/span_bench.rb`

| Operation | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| name= | 3,642,110.6 i/s | 274.57 ns/i | **Fastest** |
| set_attribute | 1,996,785.3 i/s | 500.80 ns/i | 1.82x slower |
| add_event | 268,851.5 i/s | 3.72 μs/i | 13.55x slower |

#### Tracer Span Creation

`bundle exec ruby benchmarks/tracer_bench.rb`

| Operation | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| start span with parent context | 2,619,109.2 i/s | 381.81 ns/i | **Fastest** |
| start span | 2,269,594.3 i/s | 440.61 ns/i | 1.15x slower |
| start span with attributes | 2,007,011.5 i/s | 498.25 ns/i | 1.30x slower |
| start span with links | 1,991,015.3 i/s | 502.26 ns/i | 1.32x slower |
