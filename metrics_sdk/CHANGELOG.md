# Release History: opentelemetry-metrics-sdk

### v0.7.4 / 2025-07-29

* FIXED: Validate scale range and raise exception if out of bounds for exponential histograms

### v0.7.3 / 2025-07-09

* FIXED: Stop exporting metrics with empty data points

### v0.7.2 / 2025-07-03

* FIXED: Coerce aggregation temporality to be a symbol for exponential histograms

### v0.7.1 / 2025-05-28

* FIXED: Recover periodic metric readers after forking

### v0.7.0 / 2025-05-13

* ADDED: Add basic exponential histogram

### v0.6.1 / 2025-04-09

* FIXED: Use condition signal to replace sleep and remove timeout.timeout…

### v0.6.0 / 2025-02-25

- ADDED: Support 3.1 Min Version
- FIXED: Add is_monotonic flag to sum

### v0.5.0 / 2025-01-08

- ADDED: Add synchronous gauge

### v0.4.1 / 2024-12-04

- FIXED: Handle float value in NumberDataPoint

### v0.4.0 / 2024-11-20

- ADDED: Update metrics configuration patch

### v0.3.0 / 2024-10-22

- ADDED: Add basic metrics view
- FIXED: Coerce aggregation_temporality to symbol
- FIXED: Add warning if invalid meter name given

### v0.2.0 / 2024-08-27

- ADDED: Add basic periodic exporting metric_reader

### v0.1.0 / 2024-07-31

Initial release.
