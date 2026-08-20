# Logs SDK Benchmarks

This directory contains [benchmark-ips](https://github.com/evanphx/benchmark-ips) benchmarks for the OpenTelemetry Ruby Logs SDK. They cover SDK logger provider and logger emit operations, as well as LogRecord creation and conversion.

## Running the Benchmarks

Run from the `logs_api/` directory:

```bash
# Run all benchmarks
bundle exec rake bench:all

# Or run individual benchmarks:
bundle exec ruby benchmarks/log_record_bench.rb
bundle exec ruby benchmarks/logger_bench.rb
```

## Benchmark Files

| File | What it measures |
| ---- | --------------- |
| `log_record_bench.rb` | SDK LogRecord creation with different parameter combinations and `to_log_record_data` conversion |
| `logger_bench.rb` | SDK logger provider logger acquisition and logger emit operations — with and without body, attributes, and trace context |

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

#### LogRecord Operations

`bundle exec ruby benchmarks/log_record_bench.rb`

**LogRecord Creation by Attribute Size:**

| Operation | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| LogRecord.new with 1 attribute | 360,541.7 i/s | 2.77 μs/i | **Fastest** |
| LogRecord.new with 3 attributes | 293,456.6 i/s | 3.41 μs/i | 1.23x slower |
| LogRecord.new with 8 attributes | 206,304.9 i/s | 4.85 μs/i | 1.75x slower |

**LogRecord Creation with Different Parameters:**

| Operation | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| LogRecord.new (minimal) | 664,125.2 i/s | 1.51 μs/i | **Fastest** |
| LogRecord.new with body | 553,839.4 i/s | 1.81 μs/i | 1.20x slower |
| LogRecord.new with attributes | 361,550.8 i/s | 2.77 μs/i | 1.84x slower |
| LogRecord.new with body and attributes | 357,268.8 i/s | 2.80 μs/i | 1.86x slower |

#### Logger Operations

`bundle exec ruby benchmarks/logger_bench.rb`

**Logger Emit:**

| Operation | Throughput | Time/Op | Relative Performance |
| --- | --- | --- | --- |
| sdk logger#on_emit with trace context | 288,497.2 i/s | 3.47 μs/i | **Fastest** |
| sdk logger#on_emit | 284,946.1 i/s | 3.51 μs/i | same-ish |
| sdk logger#on_emit with body | 282,043.7 i/s | 3.55 μs/i | 1.02x slower |
| sdk logger#on_emit with attributes | 201,052.2 i/s | 4.97 μs/i | 1.43x slower |
| sdk logger#on_emit with body and attributes | 200,523.9 i/s | 4.99 μs/i | 1.44x slower |
