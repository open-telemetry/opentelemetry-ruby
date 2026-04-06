# Dice Roller — OpenTelemetry Ruby Reference Application

This is the Ruby implementation of the
[OpenTelemetry Getting Started reference application](https://opentelemetry.io/docs/getting-started/reference-application-specification/).

The application is a simple HTTP service that simulates rolling one or more
six-sided dice. It comes in two flavours:

| Directory         | Description                                       |
|-------------------|---------------------------------------------------|
| `uninstrumented/` | Plain Sinatra app — no OpenTelemetry              |
| `instrumented/`   | Same app with full OTel traces, metrics, and logs |

---

## Requirements

- Ruby ≥ 3.2
- Bundler

---

## Running locally

### Uninstrumented

```bash
cd uninstrumented
bundle install
ruby app.rb
```

### Instrumented

```bash
cd instrumented
bundle install
OTEL_SERVICE_NAME=dice_roller ruby app.rb
```

By default telemetry is printed to **stdout** (console exporter).  
To send to an OpenTelemetry Collector set the exporter env vars:

```bash
OTEL_TRACES_EXPORTER=otlp \
OTEL_METRICS_EXPORTER=otlp \
OTEL_LOGS_EXPORTER=otlp \
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
OTEL_SERVICE_NAME=dice_roller \
ruby app.rb
```

You can also export your telemetry to more than one location. To send to an OpenTelemetry Collector and to the console, set the exporter env vars:

```bash
OTEL_TRACES_EXPORTER=otlp,console \
OTEL_METRICS_EXPORTER=otlp,console \
OTEL_LOGS_EXPORTER=otlp,console \
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
OTEL_SERVICE_NAME=dice_roller \
ruby app.rb
```

---

## API

### `GET /rolldice`

Roll one or more dice.

| Query parameter | Type    | Required | Description                                                       |
|-----------------|---------|----------|-------------------------------------------------------------------|
| `rolls`         | integer | No       | Number of dice to roll (default: 1). Must be a positive integer.  |
| `player`        | string  | No       | Player name — used in debug log output.                           |

#### Examples

```bash
# Roll once (default)
curl http://localhost:8080/rolldice

# Roll 3 dice
curl "http://localhost:8080/rolldice?rolls=3"

# Roll with a player name
curl "http://localhost:8080/rolldice?rolls=2&player=Alice"
```

#### Responses

| Condition                                 | Status | Body                                                                        |
|-------------------------------------------|--------|-----------------------------------------------------------------------------|
| `rolls` not set or valid positive integer | `200`  | Single integer or JSON array of integers (1–6)                              |
| `rolls` is not a number                   | `400`  | `{"status":"error","message":"Parameter rolls must be a positive integer"}` |
| `rolls` is `0` or negative                | `500`  | _(empty body)_                                                              |

---

## Running with Docker

Build and run the **instrumented** version (default):

```bash
# From the dice_roller directory
docker build --target instrumented -t dice_roller:instrumented .
docker run -p 8080:8080 \
  -e OTEL_SERVICE_NAME=dice_roller \
  dice_roller:instrumented
```

Build and run the **uninstrumented** version:

```bash
docker build --target uninstrumented -t dice_roller:uninstrumented .
docker run -p 8080:8080 dice_roller:uninstrumented
```

Override the port:

```bash
docker run -p 9090:9090 -e APPLICATION_PORT=9090 dice_roller:instrumented
```

---

## OpenTelemetry signals

The instrumented version emits the following signals:

### Resources

The application automatically detects and includes the following resource attributes:

| Attribute                        | Source                          | Description                                    |
|----------------------------------|---------------------------------|------------------------------------------------|
| `service.name`                   | `OTEL_SERVICE_NAME` env var     | Service name (e.g., `dice_roller`)             |
| `telemetry.sdk.name`             | Built-in detector               | Always `opentelemetry`                         |
| `telemetry.sdk.language`         | Built-in detector               | Always `ruby`                                  |
| `telemetry.sdk.version`          | Built-in detector               | OpenTelemetry SDK version                      |
| `process.pid`                    | Built-in detector               | Process ID                                     |
| `process.command`                | Built-in detector               | Command name                                   |
| `process.runtime.name`           | Built-in detector               | Ruby engine (e.g., `ruby`, `jruby`)            |
| `process.runtime.version`        | Built-in detector               | Ruby version                                   |
| `process.runtime.description`    | Built-in detector               | Full Ruby description                          |
| `container.id`                   | Container detector              | Container ID (when running in a container)     |

Additional attributes can be set via `OTEL_RESOURCE_ATTRIBUTES` environment variable.

### Traces

| Span name       | Kind       | Attributes                                                          |
|-----------------|------------|---------------------------------------------------------------------|
| `GET /rolldice` | `SERVER`   | HTTP semantic conventions (via Sinatra instrumentation)             |
| `roll_dice`     | `INTERNAL` | `dice.rolls`, `code.function`, `code.namespace`                     |
| `roll`          | `INTERNAL` | `dice.value`                                                        |

### Metrics

| Metric name            | Type      | Unit     | Description                             |
|------------------------|-----------|----------|-----------------------------------------|
| `dice.rolls`           | Counter   | `{roll}` | Total number of dice rolled             |
| `dice.roll.value`      | Histogram | `{roll}` | Distribution of outcomes (1–6)          |
| `dice.rolls.requested` | Gauge     | `{roll}` | Last requested number of rolls          |

### Logs

All Ruby `Logger` output is bridged to OpenTelemetry via
`opentelemetry-instrumentation-logger`.

| Level   | Condition                                |
|---------|------------------------------------------|
| `INFO`  | Every successful request                 |
| `WARN`  | Invalid `rolls` parameter (status 400)   |
| `ERROR` | Failed to roll dice (status 500)         |
| `DEBUG` | Player name and rolled value             |

---

## Environment variables

| Variable                       | Default                 | Description                                               |
|--------------------------------|-------------------------|-----------------------------------------------------------|
| `APPLICATION_PORT`             | `8080`                  | Port the server listens on                                |
| `OTEL_SERVICE_NAME`            | _(unset)_               | Service name reported in telemetry                        |
| `OTEL_RESOURCE_ATTRIBUTES`     | _(unset)_               | Additional resource attributes                            |
| `OTEL_TRACES_EXPORTER`         | `console`               | Traces exporter (`console` or `otlp`)                     |
| `OTEL_METRICS_EXPORTER`        | `console`               | Metrics exporter (`console` or `otlp`)                    |
| `OTEL_LOGS_EXPORTER`           | `console`               | Logs exporter (`console` or `otlp`)                       |
| `OTEL_EXPORTER_OTLP_ENDPOINT`  | `http://localhost:4318` | OTLP endpoint                                             |
| `OTEL_LOG_LEVEL`               | _(unset)_               | OTel internal log level (e.g. `debug`, default: `info`)   |
