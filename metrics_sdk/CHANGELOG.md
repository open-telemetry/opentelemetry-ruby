# Release History: opentelemetry-metrics-sdk

### v0.7.2 / 2025-07-01

* FIXED: Enfore the aggregation_temporality as sym for exponential_histogram

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
