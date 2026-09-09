# Logs Spec Compliance

This document tracks how the Ruby `logs_api`, `logs_sdk`, and `exporter/otlp-logs` gems align with
the [OpenTelemetry Logs specification](https://github.com/open-telemetry/opentelemetry-specification/tree/main/specification/logs)
as of 2026-08-19. It follows the same methodology as `SPEC_COMPLIANCE_METRICS.md`.

## Methodology

- **Scope**: `specification/logs/api.md`, `noop.md`, `sdk.md`, `data-model.md`, `sdk_exporters/stdout.md`.
  Logs has no dedicated `sdk_exporters/otlp.md` the way Metrics does, so the OTLP section below is
  sourced from the shared `specification/protocol/exporter.md` (the same document the Metrics doc's
  OTLP-4 row cites) cross-checked against `exporter/otlp-logs`. `data-model-appendix.md` and
  `supplementary-guidelines.md` were read in full and confirmed to contain no MUST/SHOULD/MAY
  statements — the appendix is worked examples only, and `supplementary-guidelines.md` states
  explicitly (lines 3-5) that it "does NOT add any extra requirements to the existing specifications."
  `logs/README.md` is conceptual/overview and likewise contributes no rows.
- **Requirement level**: only MUST/SHOULD/SHOULD NOT/MUST NOT statements are tracked; bare MAY
  statements are generally omitted unless they clarify an otherwise-confusing MUST/SHOULD, matching
  the Metrics doc's convention.
- **§ numbering**: self-assigned per document (`API-N`, `NOOP-N`, `SDK-N`, `DM-N`, `OTLP-N`,
  `STDOUT-N`), in the order the requirement appears in its source doc. Not spec line/section numbers.
- **Stability**: taken from each section's own `**Status**: [Stable]`/`[Development]` marker;
  `api.md`, `noop.md`, `data-model.md`, and `sdk_exporters/stdout.md` are Stable at the document
  level (except where a subsection says otherwise); `sdk.md` is Stable at the document level with
  several subsections explicitly marked `[Development]` (LoggerConfigurator, LoggerConfig, Logger's
  LoggerConfig-conformance clause, the LoggerConfig-driven filtering/Enabled clauses, the
  event-to-span-event bridge, and Self-observability).
- **Status legend**: ✅ Full · ⚠️ Partial · ❌ Missing · N/A Not applicable to this implementation.
- Every citation below was read directly from the referenced file/line; none are taken on faith from
  a summary.

---

## API (`api.md`)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| API-1 | API SHOULD provide a way to set/register and access a global default `LoggerProvider`. | Stable | ✅ | `logs_api/lib/opentelemetry-logs-api.rb:26-40` (`logger_provider=`/`logger_provider`), backed by `Internal::ProxyLoggerProvider` (`logs_api/lib/opentelemetry/internal/proxy_logger_provider.rb:15-58`). |
| API-2 | `LoggerProvider` MUST provide a "Get a Logger" operation. | Stable | ✅ | `logs_api/lib/opentelemetry/logs/logger_provider.rb:20-22`; SDK override `logs_sdk/lib/opentelemetry/sdk/logs/logger_provider.rb:44-55`. |
| API-3 | Get a Logger MUST accept `name`. | Stable (`api.md:68-81`) | ✅ | Both layers accept `name` (API positional, SDK required keyword). |
| API-4 | Get a Logger MUST accept optional `version`. | Stable (`api.md:83-84`) | ✅ | `logger_provider.rb` (API) `:20` and (SDK) `:44` both default `version` to `nil`/`''`. |
| API-5 | Get a Logger MUST accept optional `schema_url`. | Stable (`api.md:86-87`) | ❌ | Neither the no-op `LoggerProvider#logger` (`logs_api/.../logger_provider.rb:20`) nor the SDK's (`logs_sdk/.../logger_provider.rb:44`) accept a `schema_url` parameter at all — it's silently unsupported. Consistent with the org-wide `spec-compliance-matrix.md` leaving Ruby's Tracer/Meter `schema_url` cells blank too; `InstrumentationScope` itself (`sdk/lib/opentelemetry/sdk/instrumentation_scope.rb`) carries no `schema_url` field anywhere in this SDK. |
| API-6 | Get a Logger MUST accept a variable number of instrumentation-scope `attributes`, including none. | Stable (`api.md:89-91`) | ❌ | No `attributes:` parameter on either `logger_provider.rb` (API `:20` or SDK `:44`); `InstrumentationScope.new(name, version)` (`logs_sdk/.../logger.rb:25`) has no attributes slot to receive them even if the caller could pass any. |
| API-7 | `Logger` MUST provide a function to Emit a `LogRecord`. | Stable (`api.md:101-103`) | ✅ | `logs_api/lib/opentelemetry/logs/logger.rb:44-57` `#on_emit`; SDK `logs_sdk/.../logger.rb:66-92`. |
| API-8 | `Logger` SHOULD provide functions to report if `Logger` is `Enabled`. | Stable (`api.md:105-107`) | ❌ | No `enabled?`/`enabled` method exists on `OpenTelemetry::Logs::Logger` (`logs_api/lib/opentelemetry/logs/logger.rb`, the class only defines `on_emit`) nor on the SDK `Logger` (`logs_sdk/.../logger.rb`) — confirmed by reading both files in full. This is one of the largest gaps in the whole signal; see SDK-25 below for the SDK-side consequences. |
| API-9 | Emit a LogRecord MUST accept: Timestamp, ObservedTimestamp, Context (optional-if-implicit-context-supported, else required; MUST use current Context if unspecified), SeverityNumber, SeverityText, Body, Attributes, EventName (all optional). | Stable (`api.md:113-125`) | ✅ | `logs_api/lib/opentelemetry/logs/logger.rb:44-56` declares every one of these as an optional keyword arg including `context: nil`; SDK `logs_sdk/.../logger.rb:66-76` defaults `context: OpenTelemetry::Context.current` (satisfies "MUST use current Context if unspecified", `api.md:118-120`). |
| API-10 | API MAY accept an optional Exception parameter. | Stable (`api.md:127-129`) | ❌ | No `exception:` parameter anywhere in either `Logger#on_emit` signature (API or SDK) — there is no code path for exception-derived attributes at all (ties to SDK-22 below). |
| API-11 | Enabled SHOULD accept Context (same implicit/explicit rule as Emit), SeverityNumber, EventName; MUST return a language-idiomatic boolean; documentation SHOULD state Enabled is optional and its value isn't static. | Stable (`api.md:136-157`) | ❌ | Moot — there is no `Enabled` method to accept these params at all (API-8). |
| API-12 | For each optional parameter the API MUST accept it but MUST NOT obligate the user to supply it; for required parameters the API MUST obligate the user. | Stable (`api.md:164-168`) | ✅ | Every optional param across both API layers has a default value; SDK's `logger(name:, ...)` makes `name` a required keyword with no default (`logs_sdk/.../logger_provider.rb:44`), matching `name` being the one required Get-a-Logger param. |
| API-13 | `LoggerProvider` — all methods MUST be documented as safe for concurrent use by default. | Stable (`api.md:175-176`) | ✅ | SDK `LoggerProvider` guards `@registry`/`@log_record_processors`/`@stopped` with `@registry_mutex`/`@mutex` (`logs_sdk/.../logger_provider.rb:31,35,52,63,86,117`); no-op `LoggerProvider` (`logs_api/.../logger_provider.rb`) is a trivial memoized no-op. |
| API-14 | `Logger` — all methods MUST be documented as safe for concurrent use by default. | Stable (`api.md:178-179`) | ✅ | SDK `Logger#on_emit` (`logs_sdk/.../logger.rb:66-92`) holds no mutable instance state of its own; all shared state is delegated to the mutex-guarded `LoggerProvider`. |
| API-15 | Ergonomic API MAY be additionally provided; SHOULD support event semantics; SHOULD be idiomatic. | Development (`api.md:181-190`) | ❌ | No ergonomic/event-focused API layered on top of `logs_api`/`logs_sdk` (confirmed no such module in either gem). Matches the org-wide matrix's blank "Ergonomic API" cell for Ruby. |

## No-Op (`noop.md`)

Only what's distinct from the API table above (per the Metrics doc's own convention for this section).

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| NOOP-1 | No-Op MUST allow creation of multiple `LoggerProvider`s holding no state, safe for concurrent use, never erroring/logging; MAY return the same instance/Logger to every creation request. | Stable (`noop.md:30-51`) | ✅ | `logs_api/lib/opentelemetry/logs/logger_provider.rb:11,20-22` — `NOOP_LOGGER` is a single memoized singleton returned regardless of `name`/`version` (`@logger \|\|= NOOP_LOGGER`), which the spec explicitly permits (`noop.md:41-42,50-51`). No error paths exist. |
| NOOP-2 | No-Op operations MUST accept all defined parameters, MUST NOT validate them, MUST NOT error/log. | Stable (`noop.md:33-35`) | ⚠️ | Holds for the params the no-op layer *does* declare (`logs_api/.../logger.rb:44-56`, `logger_provider.rb:20`) — none are validated. But per API-5/API-6, `schema_url` and `attributes` aren't even declared as parameters to accept-without-validating in the first place, so this requirement can't be fully satisfied. |
| NOOP-3 | No-Op `Logger` MUST allow emitting LogRecords. | Stable (`noop.md:57-58`) | ✅ | `logs_api/lib/opentelemetry/logs/logger.rb:44-57` — empty-bodied `on_emit`. |
| NOOP-4 | No-Op Enabled MUST always return `false`. | Stable (`noop.md:62`) | ❌ | There is no `Enabled` method on the no-op `Logger` to return anything — calling `.enabled?`/`.enabled` on a fresh `OpenTelemetry::Logs::Logger` raises `NoMethodError` instead of behaving as a spec-compliant no-op. Direct consequence of API-8's absence. |

## SDK (`sdk.md`)

### LoggerProvider

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-1 | `LoggerProvider` MUST allow a `Resource` to be specified; SHOULD associate it with all `LogRecord`s from any `Logger`. | Stable (`sdk.md:61-63`) | ✅ | `logs_sdk/lib/opentelemetry/sdk/logs/logger_provider.rb:28,32` (`resource:` param, `@resource`), threaded into every emitted record via `on_emit` (`:147-159`, `resource: @resource`). |
| SDK-2 | SDK SHOULD allow creation of multiple independent `LoggerProvider`s. | Stable (`sdk.md:67`) | ✅ | `LoggerProvider#initialize` (`logger_provider.rb:28-36`) has no shared/global state between instances. |
| SDK-3 | It SHOULD only be possible to create `Logger`s through a `LoggerProvider`. | Stable (`sdk.md:71-72`) | ⚠️ | Enforced only by convention/documentation (`logs_sdk/lib/opentelemetry/sdk/logs/logger.rb:14-16` docstring "This should not be called directly") — `Logger.new(name, version, logger_provider)` is a fully public constructor with no visibility restriction, so nothing in the language actually prevents direct instantiation. |
| SDK-4 | `LoggerProvider` MUST implement the Get-a-Logger API. | Stable (`sdk.md:74`) | ✅ | `logger_provider.rb:44-55`. (Inherits the `schema_url`/`attributes` gaps from API-5/API-6.) |
| SDK-5 | User input MUST be used to create an `InstrumentationScope` stored on the `Logger`. | Stable (`sdk.md:76-78`) | ✅ | `logs_sdk/.../logger.rb:25` `@instrumentation_scope = InstrumentationScope.new(name, version)`. |
| SDK-6 | Invalid (null/empty) `name` MUST still return a working `Logger` fallback (not null/exception); its name SHOULD keep the original invalid value; SHOULD log a warning. | Stable (`sdk.md:80-83`) | ✅ | `logger_provider.rb:47-50` warns "invalid name" but still proceeds to `Logger.new(name, ...)` (`:53`) with the original value untouched. |
| SDK-7 | **[Development]** `LoggerProvider` MUST compute the `LoggerConfig` via a configured `LoggerConfigurator` and create Loggers that conform to it. | Development (`sdk.md:85-88`) | ❌ | No `LoggerConfigurator`/`LoggerConfig` class exists anywhere in `logs_sdk` (confirmed by reading every file under `logs_sdk/lib`). |
| SDK-8 | Configuration (`LogRecordProcessor`s and, Development, `LoggerConfigurator`) MUST be owned by the `LoggerProvider`; MAY be applied at creation time. | Stable (`sdk.md:92-95`) | ⚠️ | Processors are owned by `LoggerProvider` (`@log_record_processors`, `logger_provider.rb:29`) — ✅ for that half. `LoggerConfigurator` doesn't exist (SDK-7) — ❌ for that half. |
| SDK-9 | If configuration is updated (e.g. adding a processor), the update MUST also apply to all already-returned `Logger`s. | Stable (`sdk.md:97-99`) | ✅ | `add_log_record_processor` (`logger_provider.rb:62-71`) mutates the shared `@log_record_processors` array; every `Logger` routes emission back through the same `LoggerProvider#on_emit` (`:161`), which reads that array live — no per-`Logger` snapshot exists to go stale. |
| SDK-10 | **[Development]** `LoggerConfigurator`: function accepting `logger_scope`, returning a `LoggerConfig` or a default-signal; called on Logger creation and on every outstanding Logger when the configurator updates. | Development (`sdk.md:112-126`) | ❌ | Doesn't exist (SDK-7). |
| SDK-11 | `Shutdown` MUST be called only once per `LoggerProvider`; after it, subsequent Get-a-Logger calls are not allowed and SHOULD return a no-op `Logger`. | Stable (`sdk.md:142-144`) | ⚠️ | The "called only once" half is enforced (`logger_provider.rb:87-90` warns and returns `FAILURE` on a second `shutdown` call). But `#logger` (`:44-55`) never checks `@stopped` at all — calling `logger_provider.logger(name: 'x')` **after** `shutdown` still returns a fully functional `Logger` wired to the same (now-shutdown) processors, not a no-op fallback. |
| SDK-12 | `Shutdown` SHOULD report succeeded/failed/timed-out; SHOULD complete/abort within a timeout. | Stable (`sdk.md:146-152`) | ✅ | Returns `Export::SUCCESS`/`FAILURE`/`TIMEOUT` (`logger_provider.rb:89,95,101`), tracks remaining timeout across processors via `OpenTelemetry::Common::Utilities.maybe_timeout` (`:92-98`). |
| SDK-13 | `Shutdown` MUST invoke `Shutdown` on all registered `LogRecordProcessor`s. | Stable (`sdk.md:154-155`) | ✅ | `logger_provider.rb:93-98`. |
| SDK-14 | `ForceFlush` MUST invoke `ForceFlush` on all registered `LogRecordProcessor`s; SHOULD report status/timeout. | Stable (`sdk.md:159-175`) | ✅ | `logger_provider.rb:116-130`, mutex-guarded, per-processor timeout budgeting, `SUCCESS` if already stopped (`:118`). |

### Logger / LoggerConfig (Development)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-15 | `Logger` MUST behave per the `LoggerConfig` computed at creation, and MUST update if the `LoggerConfigurator` updates. | Development (`sdk.md:179-183`) | ❌ | No `LoggerConfig` concept exists (SDK-7). |
| SDK-16 | `LoggerConfig.enabled`: defaults to `true`; when `false`, `Logger` MUST behave like the No-Op Logger. | Development (`sdk.md:192-198`) | ❌ | Not implemented. |
| SDK-17 | `LoggerConfig.minimum_severity`: defaults to `0`; log records with a specified (non-zero) severity below it MUST be dropped; unspecified-severity records bypass this filter. | Development (`sdk.md:200-208`) | ❌ | Not implemented — no severity-threshold filtering anywhere in `logs_sdk`. |
| SDK-18 | `LoggerConfig.trace_based`: defaults to `false`; when `true`, log records associated with an unsampled trace (valid `SpanId`, `TraceFlags` SAMPLED unset) MUST be dropped. | Development (`sdk.md:210-222`) | ❌ | Not implemented. |
| SDK-19 | Changes to `LoggerConfig` params don't need to be immediately visible to `Enabled` callers but MUST be eventually visible. | Development (`sdk.md:224-226`) | N/A | Moot — no `LoggerConfig` exists to have visibility semantics. |

### Emit a LogRecord / Enabled

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-20 | If ObservedTimestamp is unspecified, the implementation SHOULD set it equal to the current time. | Stable (`sdk.md:230-231`) | ⚠️ | Through the public `Logger#on_emit` path (`logs_sdk/.../logger.rb:67`), the keyword default `observed_timestamp: Time.now` is evaluated at call time, so an unspecified value does become "now" — ✅ at that entry point. But `SDK::Logs::LogRecord#initialize` itself (`logs_sdk/.../log_record.rb:80`) computes `observed_timestamp \|\| timestamp \|\| Time.now` — i.e. it prefers a caller-supplied `timestamp` over "current time" when constructed directly (as `LoggerProvider#on_emit` and any direct `LogRecord.new` caller do) — a different rule than the literal `sdk.md:230-231` text (though it does match the *description* of the field itself, `data-model.md:192-198`, which says the two are typically equal at generation time). Net: the two code paths disagree with each other on which reading of the spec to satisfy. |
| SDK-21 | If an Exception is provided, the SDK MUST by default set exception-semconv attributes on the `LogRecord`; user-provided attributes MUST take precedence and MUST NOT be overwritten. | Stable (`sdk.md:233-237`) | ❌ | No `exception:` parameter and no exception-to-attributes bridging code exists anywhere in `logs_sdk` or `logs_api` (API-10). |
| SDK-22 | **[Development]** Before processing, filtering rules from `LoggerConfig` (Enabled, minimum-severity, trace-based) MUST be applied. | Development (`sdk.md:244-259`) | ❌ | Not implemented (depends on SDK-16/17/18). |
| SDK-23 | `Enabled` MUST return `false` when there are no registered `LogRecordProcessor`s, or when all registered processors implement `Enabled` and all return `false`; otherwise SHOULD return `true`. | Stable (`sdk.md:263-265,274-277`) | ❌ | There is no `Enabled` method on the SDK `Logger` at all (confirmed: `logs_sdk/lib/opentelemetry/sdk/logs/logger.rb` defines only `initialize`/`on_emit`) — this Stable MUST is entirely unimplemented, not merely partial. |
| SDK-24 | **[Development]** `Enabled` MUST also return `false` per `LoggerConfig.enabled`/`minimum_severity`/`trace_based`. | Development (`sdk.md:266-273`) | ❌ | Moot — SDK-23's prerequisite doesn't exist either. |

### ReadableLogRecord / ReadWriteLogRecord

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-25 | `ReadableLogRecord` MUST expose all information added to the `LogRecord`, plus (implicitly) `InstrumentationScope` and `Resource`. | Stable (`sdk.md:286-290`) | ✅ | `logs_sdk/.../log_record.rb:16-27` — every field is an `attr_accessor`, including `resource` and `instrumentation_scope`. |
| SDK-26 | Trace context fields MUST be populated from the resolved `Context` when emitted. | Stable (`sdk.md:292-294`) | ✅ | `logs_sdk/.../logger.rb:77-89` — pulls `trace_id`/`span_id`/`trace_flags` from `OpenTelemetry::Trace.current_span(context)` whenever the caller didn't supply them explicitly. |
| SDK-27 | Counts for attributes dropped due to collection limits MUST be available to exporters. | Stable (`sdk.md:296-299`) | ✅ | `total_recorded_attributes` is captured before trimming (`log_record.rb:92,94`) and carried into `LogRecordData` (`:97-113`, `log_record_data.rb:23`); consumed by the OTLP exporter to compute `dropped_attributes_count` (`exporter/otlp-logs/.../logs_exporter.rb:312`). |
| SDK-28 | `ReadWriteLogRecord` MUST additionally allow modifying Timestamp, ObservedTimestamp, SeverityText, SeverityNumber, Body, Attributes, TraceId, SpanId, TraceFlags, EventName. | Stable (`sdk.md:309-321`) | ✅ | All ten are plain `attr_accessor`s on `SDK::Logs::LogRecord` (`log_record.rb:16-27`) — fully mutable pre-export. |
| SDK-29 | SDK MAY provide a deep-clone operation for `ReadWriteLogRecord`, for use by concurrent processors. | Stable, MAY (`sdk.md:323-326`) | ❌ | No clone/dup override or explicit deep-clone method on `SDK::Logs::LogRecord` (`log_record.rb`). Low severity (MAY), but see SDK-40 below for the concrete consequence in `BatchLogRecordProcessor`. |

### LogRecord Limits

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-30 | `LogRecord` attributes MUST adhere to the common attribute-limit rules; if implemented, the SDK MUST provide a way to change the limits via `LoggerProvider` configuration; options MAY be bundled as `LogRecordLimits`. | Stable (`sdk.md:330-338`) | ✅ | `logs_sdk/lib/opentelemetry/sdk/logs/log_record_limits.rb` — a dedicated `LogRecordLimits` class, injected via `LoggerProvider.new(log_record_limits:)` (`logger_provider.rb:28`). Defaults match the common-attribute-limits spec exactly: `attribute_count_limit` reads `OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT` → `OTEL_ATTRIBUTE_COUNT_LIMIT` → **128** (`log_record_limits.rb:22-26`); `attribute_length_limit` reads `OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT` → `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` → **no limit** (`:27-30`) — confirmed against `specification/configuration/sdk-environment-variables.md:203-204`. |
| SDK-31 | SHOULD log a message when an attribute is discarded due to a limit; the message MUST be printed at most once per `LogRecord` (not per discarded attribute). | Stable (`sdk.md:354-357`) | ⚠️ | Two separate gaps: (1) the attribute-**count** truncation path (`log_record.rb:138-141`, `truncate_attributes`) drops excess attributes via `attributes.shift` with **no logging call at all**; (2) the attribute-**validity** path (`:143-159`, `validate_attributes`) calls `OpenTelemetry.handle_error` **once per invalid attribute** inside the `keep_if` block, so a record with 3 bad attributes logs 3 messages — the opposite problem, over-logging rather than the required "at most once per LogRecord". |

### LogRecordProcessor

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-32 | Processors registered on `LoggerProvider` MUST be invoked in the order registered. | Stable (`sdk.md:367-368`) | ✅ | `add_log_record_processor` appends (`logger_provider.rb:69`); `on_emit` iterates with `.each` in that same order (`:161`). |
| SDK-33 | SDK MUST allow each pipeline to end with an individual exporter; MUST allow custom processors and decorating built-ins. | Stable (`sdk.md:371-376`) | ✅ | `LogRecordProcessor` is an explicitly duck-typed interface (`log_record_processor.rb:10-13`); `Simple`/`BatchLogRecordProcessor` each take one `exporter`; any object satisfying the 3-method interface can be registered. |
| SDK-34 | `OnEmit` is called synchronously on the emitting thread; SHOULD NOT block or throw. `logRecord` mutations MUST be visible to subsequently-registered processors. A processor MAY freely modify `logRecord` during the call; concurrent-safety of `ReadWriteLogRecord` is OPTIONAL, and implementations SHOULD recommend a clone for concurrent processing. | Stable (`sdk.md:404-425`) | ⚠️ | Synchronous call + mutation-visibility ✅: `logger_provider.rb:161` passes the **same** `LogRecord` object reference to every processor in turn, so processor A's edits are visible to processor B. `SimpleLogRecordProcessor#on_emit` also rescues all exceptions (`export/simple_log_record_processor.rb:49-50`), satisfying "SHOULD NOT throw" defensively. But `BatchLogRecordProcessor#on_emit` (`export/batch_log_record_processor.rb:70-83`) enqueues the **live** `LogRecord` object for asynchronous export later by the background thread — it never clones it (ties to SDK-29's missing clone operation) — so a caller that mutates the record after `on_emit` returns can race with the background thread's later `.to_log_record_data` call. The spec makes this optional to guard against, but doesn't recommend a clone anywhere in this code path either. |
| SDK-35 | `Enabled` MAY be implemented on a `LogRecordProcessor`, returning `false` if a would-be `LogRecord` should be filtered; MUST default to `true` for indeterminate state; wrapping processors' `OnEmit` should never call the wrapped processor's `Enabled`. | Stable, MAY (`sdk.md:429-464`) | ❌ | No `enabled` method on the base `LogRecordProcessor` (`log_record_processor.rb`) or either built-in processor. Low severity (MAY) but compounds the Logger-level `Enabled` absence (SDK-23) — there's no filtering fast-path anywhere in the pipeline. |
| SDK-36 | `Shutdown` SHOULD be called once; subsequent `OnEmit` calls are not allowed and SHOULD be ignored gracefully; SHOULD report status; MUST include the effects of `ForceFlush`. | Stable (`sdk.md:471-478`) | ⚠️ | Post-shutdown `OnEmit` is correctly a no-op in both built-ins (`simple_log_record_processor.rb:46`, `batch_log_record_processor.rb:71`, both `return if @stopped`). `BatchLogRecordProcessor#shutdown` explicitly calls `force_flush` (`:149`) ✅. `SimpleLogRecordProcessor#shutdown`/`#force_flush` (`simple_log_record_processor.rb:65-83`) `return if @stopped` with **no explicit return value** (i.e. `nil`) instead of one of `SUCCESS`/`FAILURE`/`TIMEOUT` when called on an already-stopped processor — a minor status-reporting deviation. |
| SDK-37 | `ForceFlush` is a hint to complete pending export tasks ASAP; built-in processors MUST try to `Export` all pending records then `ForceFlush` the exporter; MUST prioritize honoring a specified timeout. | Stable (`sdk.md:487-499`) | ✅ | `BatchLogRecordProcessor#force_flush` (`export/batch_log_record_processor.rb:96-129`) drains the queue in batches, exports each, then calls `@exporter.force_flush` (`:113`), returning `TIMEOUT` as soon as the budget is exhausted (`:106`) and re-queueing any unexported remainder (`:114-128`). `SimpleLogRecordProcessor#force_flush` delegates straight to the exporter (`:68`) — trivially compliant since every record was already exported synchronously at `on_emit` time. |
| SDK-38 | Both a Simple and a Batching processor MUST be provided by the standard SDK. | Stable (`sdk.md:516-517`) | ✅ | `export/simple_log_record_processor.rb`, `export/batch_log_record_processor.rb`. |
| SDK-39 | Simple processor MUST synchronize calls to the exporter's `Export` so they're never concurrent; configurable param: `exporter`. | Stable (`sdk.md:533-538`) | ✅ | Single-threaded synchronous call at `on_emit` time (`export/simple_log_record_processor.rb:48`) — nothing else can call `Export` concurrently through this processor. |
| SDK-40 | Batching processor MUST synchronize `Export` calls; params: `exporter`, `maxQueueSize` (default 2048), `scheduledDelayMillis` (default 1000), `exportTimeoutMillis` (default 30000), `maxExportBatchSize` (default 512, must be ≤ `maxQueueSize`). | Stable (`sdk.md:546-559`) | ✅ | `export/batch_log_record_processor.rb:37-46` — exact defaults (`OTEL_BLRP_EXPORT_TIMEOUT`→30000, `OTEL_BLRP_SCHEDULE_DELAY`→1000, `OTEL_BLRP_MAX_QUEUE_SIZE`→2048, `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE`→512), with an `ArgumentError` guard (`:43-46`) enforcing `max_export_batch_size <= max_queue_size`. `@export_mutex.synchronize` around every `@exporter.export` call (`:186`) serializes exports. |
| SDK-41 | **[Development]** Event-to-span-event bridge: MUST convert qualifying LogRecords (non-empty EventName, valid TraceId/SpanId, current span recording, matching IDs) into exactly one span event with mapped name/timestamp/attributes; MUST NOT block the record's normal pipeline; no configurable params. | Development (`sdk.md:561-600`) | ❌ | No such processor exists anywhere in `logs_sdk` (confirmed by directory listing — no bridge-related file). | 

### LogRecordExporter

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-42 | Each `LogRecordExporter` implementation MUST document its concurrency characteristics. | Stable (`sdk.md:612-613`) | ⚠️ | `InMemoryLogRecordExporter` is internally mutex-protected and its class docs imply test-safety (`export/in_memory_log_record_exporter.rb:39,47,69,94`). Neither `ConsoleLogRecordExporter` (`export/console_log_record_exporter.rb`) nor the OTLP `LogsExporter` (`exporter/otlp-logs/.../logs_exporter.rb`) document (or possess) any concurrency guarantee for concurrent `export`/`shutdown` calls on the same instance. |
| SDK-43 | `Export` should not be called concurrently with itself for the same exporter instance. | Stable (`sdk.md:625-626`) | ✅ | Enforced at the call site: `BatchLogRecordProcessor#export_batch` wraps every `@exporter.export` call in `@export_mutex.synchronize` (`export/batch_log_record_processor.rb:186`), and `SimpleLogRecordProcessor` only ever calls `export` synchronously from the single emitting thread. The exporters themselves add no independent protection (see SDK-42), but nothing in this codebase's own pipelines calls `Export` concurrently on one instance. |
| SDK-44 | `Export` MUST NOT block indefinitely — a reasonable timeout MUST apply. | Stable (`sdk.md:635-636`) | ✅ | OTLP: per-attempt `@http.open_timeout`/`read_timeout`/`write_timeout` set from the remaining timeout budget every call (`exporter/otlp-logs/.../logs_exporter.rb:166-168`, reset in `ensure` at `:231-234`). Console/InMemory are synchronous in-process operations with nothing to block on. |
| SDK-45 | Concurrent requests and retry logic are the exporter's responsibility; built-in `LogRecordProcessor`s SHOULD NOT implement retry. | Stable (`sdk.md:638-640`) | ✅ | Neither `SimpleLogRecordProcessor` nor `BatchLogRecordProcessor` retries a failed export; the OTLP exporter implements its own retry/backoff (see OTLP-16 below). |
| SDK-46 | `ForceFlush` is a hint to complete pending exports ASAP; SHOULD report status; SHOULD only be called when absolutely necessary; SHOULD honor a timeout. | Stable (`sdk.md:669-682`) | ✅ | All three shipped exporters implement `force_flush` returning `SUCCESS` (`export/console_log_record_exporter.rb:27-29`, `export/in_memory_log_record_exporter.rb:83-85`, `exporter/otlp-logs/.../logs_exporter.rb:99-101`) — trivially correct since none of them buffer data internally between `export` calls. |
| SDK-47 | `Shutdown` SHOULD be called once; after it, `Export` is not allowed and SHOULD return `Failure`; `Shutdown` SHOULD NOT block indefinitely. | Stable (`sdk.md:690-694`) | ✅ | Base `LogRecordExporter#shutdown`/`#export` (`export/log_record_exporter.rb:30-34,50-53`) — `@stopped` gate returns `FAILURE` post-shutdown. Same pattern independently re-implemented and confirmed in `ConsoleLogRecordExporter` (`:19-20,31-34`), `InMemoryLogRecordExporter` (`:70,93-99`), and the OTLP `LogsExporter` (`@shutdown` flag, `logs_exporter.rb:88-90,108-112`) — all four exporters correctly block post-shutdown exports. |

### Concurrency requirements / Self-observability

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| SDK-48 | `LoggerProvider`: Logger creation, `ForceFlush`, `Shutdown` MUST be safe for concurrent calls. | Stable (`sdk.md:707-708`) | ✅ | `logger_provider.rb` uses `@registry_mutex` for `#logger` (`:52`) and `@mutex` for `#shutdown`/`#force_flush`/`#add_log_record_processor` (`:63,86,117`). |
| SDK-49 | `Logger`: all methods MUST be safe for concurrent calls. | Stable (`sdk.md:710`) | ✅ | `logs_sdk/.../logger.rb` holds no mutable instance state beyond values fixed at construction (`@instrumentation_scope`, `@logger_provider`); real work is delegated to the mutex-guarded `LoggerProvider`. |
| SDK-50 | `LogRecordExporter`: `ForceFlush` and `Shutdown` MUST be safe for concurrent calls. | Stable (`sdk.md:712-713`) | ⚠️ | `InMemoryLogRecordExporter` guards both with `@mutex` (`export/in_memory_log_record_exporter.rb:83-85,93-99`) ✅. `ConsoleLogRecordExporter#force_flush`/`#shutdown` (`:27-34`) have no synchronization at all around the `@stopped` flag. The OTLP exporter's `#shutdown` (`logs_exporter.rb:108-112`) likewise mutates `@shutdown`/calls `@http.finish` with no mutex — a concurrent `shutdown` racing an in-flight `export`'s use of `@http` is not guarded against anywhere in this file. |
| SDK-51 | **[Development]** Logs SDK SHOULD support SDK self-observability. | Development (`sdk.md:719`) | ❌ | No self-observability instrumentation anywhere in `logs_sdk` (no `otel.sdk.*` metrics of any kind, confirmed by inspection of every file in `logs_sdk/lib`). |

---

## Data Model (`data-model.md`)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| DM-1 | `Body` MUST support `AnyValue` to preserve the semantics of structured logs. | Stable (`data-model.md:399-400`) | ⚠️ | `SDK::Logs::LogRecord#body` accepts and stores any Ruby value untyped (`logs_sdk/.../log_record.rb:69,83`); the OTLP encoder's `as_otlp_any_value` (`exporter/otlp-logs/.../logs_exporter.rb:328-347`) maps `String`/`Integer`/`Float`/`true`/`false`/`Array`/`Hash` to the matching `AnyValue` variant. Values of any other Ruby type (`nil`, `Symbol`, `Time`, `BigDecimal`, etc.) fall through the `case` with no matching branch and silently encode as an **empty** `AnyValue` (all oneof fields unset) rather than a distinct null/failure signal — a silent-data-loss edge case, e.g. `body: nil` is indistinguishable on the wire from an explicitly-empty `AnyValue`. |
| DM-2 | If `SpanId` is present, `TraceId` SHOULD also be present. | Stable (`data-model.md:222-223`) | N/A | A data-quality guideline for whoever populates the fields, not an SDK-enforceable invariant — `LogRecord#initialize` (`log_record.rb:72-73,86-87`) stores `trace_id`/`span_id` independently with no cross-field validation, which is consistent with how this class of SHOULD is typically left to callers rather than the SDK. |
| DM-3 | `SeverityNumber=0` MAY represent an unspecified value. | Stable (`data-model.md:271`) | ✅ | `logs_api/lib/opentelemetry/logs/severity_number.rb:10` `SEVERITY_NUMBER_UNSPECIFIED = 0`. |
| DM-4 | `SeverityNumber` range table (1-4 TRACE…TRACE4, 5-8 DEBUG…DEBUG4, 9-12 INFO…INFO4, 13-16 WARN…WARN4, 17-20 ERROR…ERROR4, 21-24 FATAL…FATAL4) with exact per-value short names. | Stable (`data-model.md:262-269,338-363`) | ❌ | `logs_api/lib/opentelemetry/logs/severity_number.rb:15-18` defines `SEVERITY_NUMBER_DEBUG = 5`, `SEVERITY_NUMBER_DEBUG2 = 7`, `SEVERITY_NUMBER_DEBUG3 = 6`, `SEVERITY_NUMBER_DEBUG4 = 8` — **DEBUG2 and DEBUG3 are swapped**. The spec's table (`data-model.md:345-346`) requires `DEBUG2 = 6` and `DEBUG3 = 7`. Every other constant in the file (TRACE/TRACE2-4, INFO/INFO2-4, WARN/WARN2-4, ERROR/ERROR2-4, FATAL/FATAL2-4, lines 10-14,19-34) is correctly numbered — this is an isolated two-value transcription bug, not a systemic issue, but it means any log emitted at Ruby's `SEVERITY_NUMBER_DEBUG2` carries the wrong wire value (7, i.e. DEBUG3) and vice versa. |
| DM-5 | Errors/exceptions included in `Attributes` MUST follow the OTel exception-attribute semantic conventions. | Stable (`data-model.md:442-443`) | ❌ | Moot for the SDK's own emission path since there is no exception-to-attribute bridging at all (SDK-21) — any semconv-compliant exception attributes would have to be added manually by the caller, which is outside the SDK's control either way. |
| DM-6 | `EventName` SHOULD uniquely identify the event structure (attributes and body). | Stable (`data-model.md:445-450`) | ✅ | `event_name` is accepted, stored, and exported as a free-form string with no SDK-side validation or mutation (`log_record.rb:71,85`; `log_record_data.rb:17`; `logs_exporter.rb:313`) — correctly left to the caller to name meaningfully, consistent with this being descriptive guidance rather than an enforceable rule. |

---

## OTLP Logs Exporter

Sourced from the shared `specification/protocol/exporter.md` (Logs has no dedicated
`sdk_exporters/otlp.md`), cross-checked against `exporter/otlp-logs/lib/opentelemetry/exporter/otlp/logs/logs_exporter.rb`.

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| OTLP-1 | Endpoint (HTTP): per-signal env var override takes precedence and is used as-is; otherwise the generic `OTEL_EXPORTER_OTLP_ENDPOINT` is used as a base with `v1/logs` appended; default `http://localhost:4318`. | Stable (`exporter.md:16-29,104-121`) | ✅ | `logs_exporter.rb:53` (`OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` → `OTEL_EXPORTER_OTLP_ENDPOINT` → default `http://localhost:4318/v1/logs`); `:64-69` builds `URI.join(endpoint, 'v1/logs')` specifically when the resolved value came from the *generic* endpoint var, and uses a per-signal endpoint URL as-is otherwise — matches `exporter.md`'s Example 1/3 construction rules. |
| OTLP-2 | If a per-signal endpoint URL has no path component, the root path `/` MUST be used (not silently dropped). | Stable (`exporter.md:110-111`, Example 2) | ⚠️ | For a per-signal endpoint (e.g. `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://collector:4318`), `:68` does `URI(endpoint)` as-is; `URI('http://collector:4318').path` is `''` (empty string), not `'/'`, and that empty string becomes `@path` (`:73`), then `Net::HTTP::Post.new(@path)` (`:145`) — the root-path normalization the spec requires isn't performed anywhere in this constructor. |
| OTLP-3 | Certificate File / Client key file / Client certificate file, each with a per-signal-then-generic env var fallback. | Stable (`exporter.md:41-54`) | ✅ | `logs_exporter.rb:54-56` (`_LOGS_CERTIFICATE`/`_LOGS_CLIENT_CERTIFICATE`/`_LOGS_CLIENT_KEY` → generic), applied via `http.ca_file`/`http.cert`/`http.key` (`:124-126`). |
| OTLP-4 | Headers, comma-separated `k=v` pairs (W3C-Baggage-like format), per-signal-then-generic env var. | Stable (`exporter.md:56-59,186-188`) | ✅ | `logs_exporter.rb:58` (`OTEL_EXPORTER_OTLP_LOGS_HEADERS` → `OTEL_EXPORTER_OTLP_HEADERS`); `parse_headers` (`:362-380`) splits on `,` then `=`. |
| OTLP-5 | Compression: supported values `gzip`/`none`, per-signal-then-generic env var. | Stable (`exporter.md:61-64,99-102`) | ✅ | `logs_exporter.rb:59,62` (env var + `%w[gzip none]` validation), applied at `:146-151` (`Zlib.gzip` + `Content-Encoding: gzip`). |
| OTLP-6 | Timeout, default 10s, per-signal-then-generic env var. | Stable (`exporter.md:66-69`) | ✅ | `logs_exporter.rb:60` (`OTEL_EXPORTER_OTLP_LOGS_TIMEOUT` → `OTEL_EXPORTER_OTLP_TIMEOUT`, default `10`). |
| OTLP-7 | Max Request Size (default 64 MiB) / Max Response Size (default 4 MiB) SHOULD be enforced. | Stable (`exporter.md:71-78`) | ❌ | No request- or response-size check anywhere in `logs_exporter.rb`. Consistent with the org-wide `spec-compliance-matrix.md`, which leaves the "Enforces request/response size limit" cells blank for every language, Ruby included — an ecosystem-wide gap, not a logs-specific regression. |
| OTLP-8 | Protocol option: SHOULD support both `grpc` and `http/protobuf`, MUST support at least one; default `http/protobuf`. | Stable (`exporter.md:79-83,169-184`) | ⚠️ | Ruby's `exporter/otlp-logs` implements only HTTP/protobuf — satisfies "MUST support at least one" ✅, and `logs_sdk/.../configurator_patch.rb:46-58` checks `OTEL_EXPORTER_OTLP_LOGS_PROTOCOL`/`OTEL_EXPORTER_OTLP_PROTOCOL`, warning and disabling export for anything other than `'http/protobuf'`. No gRPC transport exists at all, so the "SHOULD support both" bar isn't met — matches the org matrix's blank Ruby cell for "OTLP/gRPC exporter". |
| OTLP-9 | Retry: transient errors MUST be handled with exponential backoff with jitter. | Stable (`exporter.md:190-192`) | ✅ | `backoff?` (`logs_exporter.rb:253-272`) uses `rand(2**retry_count)` jitter, capped at `RETRY_COUNT = 5` (`:33-34,254`), and honors a numeric-or-HTTP-date `Retry-After` header when present (`:257-266`). |
| OTLP-10 | Transient errors = retryable HTTP status codes plus connection-level failure scenarios. | Stable (`exporter.md:194-209`) | ✅ | Retries on `503`/`429` (honoring `Retry-After`, `:176-180`), `408`/`504`/`502` (`:181-185`), and `Net::OpenTimeout`/`ReadTimeout`/`OpenSSL::SSL::SSLError`/`SocketError`/`SystemCallError`/`EOFError`/`Zlib::DataError` (`:201-224`). Non-retryable `404`/`400`/other 4xx/5xx correctly fail fast without retry (`:186-191`). |
| OTLP-11 | HTTP redirects SHOULD be followed (general OTLP/HTTP connection-handling expectation referenced at `exporter.md:206-209`). | Stable | ❌ | `Net::HTTPRedirection` responses close the connection and call `handle_redirect(response['location'])` (`logs_exporter.rb:192-195`), but `handle_redirect` (`:237-239`) is a literal no-op (just a `# TODO` comment) — the subsequent `redo` (`:195`) resends the identical request to the **original** `@path`/`@http`, never the `Location` from the response. Same class of gap the Metrics OTLP exporter has (documented as OTLP-10 in `SPEC_COMPLIANCE_METRICS.md`). |
| OTLP-12 | User-Agent SHOULD identify the exporter, language, and version, formatted per RFC 7231; a caller-supplied product identifier SHOULD be prepended ahead of the exporter's own string. | Stable (`exporter.md:211-225`) | ✅ | `DEFAULT_USER_AGENT = "OTel-OTLP-Exporter-Ruby/#{VERSION} Ruby/#{RUBY_VERSION} (...)"` (`logs_exporter.rb:39`); `prepare_headers` (`:349-360`) builds `"#{existing_user_agent} #{DEFAULT_USER_AGENT}".strip` — matches the spec's own worked example ordering (`MyDistribution/x.y.z OTel-OTLP-Exporter-Python/1.2.3`, `exporter.md:224`). |
| OTLP-13 | `ExportLogsServiceResponse.partial_success` (`rejected_log_records`, `error_message`) SHOULD be handled/logged on an otherwise-2xx response. | (general OTLP protocol behavior, cf. Metrics doc's equivalent finding) | ❌ | On `Net::HTTPSuccess`, the response body is read and discarded (`logs_exporter.rb:174`) without ever decoding it as `Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceResponse` — the `partial_success` field (present in the generated protobuf, `logs_service_pb.rb`) is never inspected. |
| OTLP-14 | Resource/Scope `schema_url` SHOULD be carried through to `ResourceLogs`/`ScopeLogs`. | (data-model.md:404-425 field-carrying expectation) | ❌ | `encode`'s `Resource.new`/`InstrumentationScope.new` construction (`logs_exporter.rb:280-296`) never sets `schema_url` on either message. Root cause is upstream of this exporter: neither `OpenTelemetry::SDK::Resources::Resource` nor `OpenTelemetry::SDK::InstrumentationScope` (in the main `sdk` gem) carry a `schema_url` attribute at all — the same systemic gap the org-wide `spec-compliance-matrix.md` already shows blank for Ruby's Tracer/Meter `schema_url` support (API-5 above). |
| OTLP-15 | `TraceFlags` encoding onto the wire `flags` field. | (data-model.md `TraceFlags` field semantics) | ⚠️ | `as_otlp_log_record` reads `log_record_data.trace_flags.instance_variable_get(:@flags)` (`logs_exporter.rb:314`) — this only works when `trace_flags` is an `OpenTelemetry::Trace::TraceFlags` object (the case when it's auto-derived from the current span context, `logs_sdk/.../logger.rb:78,89`). If a caller instead passes a raw `Integer` explicitly (which is what the SDK's own API docs describe the field as — `log_record_data.rb:20` says "optional Integer (8-bit byte of bit flags)"), `Integer#instance_variable_get(:@flags)` silently returns `nil` rather than the intended bit value, with no error raised. |

---

## Stdout Exporter (`sdk_exporters/stdout.md`)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
|---|---|---|---|---|
| STDOUT-1 | Output format is unspecified and can vary; documentation SHOULD warn users it's for debugging/learning only, not production. | Stable (`stdout.md:12-18`) | ⚠️ | `ConsoleLogRecordExporter#export` (`logs_sdk/.../export/console_log_record_exporter.rb:19-25`) pretty-prints each `LogRecordData` via `pp` — an unspecified, implementation-defined format ✅. The class doc (`:11-13`, "Potentially useful for exploratory purposes") gestures at the intent but doesn't carry the spec's recommended explicit warning that the format can change at any time and isn't production-recommended. |
| STDOUT-2 | SDK authors MAY choose any idiomatic name (ConsoleExporter, StdoutExporter, etc.). | Stable, MAY (`stdout.md:25-27`) | ✅ | Named `ConsoleLogRecordExporter` — an accepted idiomatic choice. |
| STDOUT-3 | If the language auto-configures a `LogRecordProcessor` to pair with this exporter (e.g. via `OTEL_LOGS_EXPORTER`), it SHOULD default to pairing with the **Simple** processor. | Stable (`stdout.md:29-34`) | ✅ | `logs_sdk/lib/opentelemetry/sdk/logs/configurator_patch.rb:44` — `when 'console' then Logs::Export::SimpleLogRecordProcessor.new(Logs::Export::ConsoleLogRecordExporter.new)` — correctly Simple, not Batch. |

---

## Summary of gaps

### Stable — missing entirely

- **`Logger#enabled?`** (API-8, NOOP-4, SDK-23): no `Enabled` method exists anywhere in `logs_api` or `logs_sdk` — a Stable SHOULD/MUST with real performance implications (its whole purpose is letting callers skip expensive `LogRecord` construction), and the no-op layer can't even satisfy noop.md's "MUST always return false" since the method doesn't exist to call.
- **`schema_url` / `attributes` on Get-a-Logger** (API-5, API-6): silently unsupported; `schema_url` is a systemic gap across the whole Ruby SDK (Tracer/Meter/Logger all lack it), not logs-specific.
- **Exception parameter on Emit-a-LogRecord** (API-10, SDK-21): no way to pass an exception and have the SDK derive semconv attributes from it.
- **Post-shutdown Get-a-Logger no-op fallback** (SDK-11): `LoggerProvider#logger` never checks `@stopped`, so it keeps handing out fully-functional Loggers after `shutdown`.
- **`SeverityNumber` DEBUG2/DEBUG3 swap** (DM-4): `severity_number.rb:16-17` has the two values transposed relative to the spec's table — a concrete, easily-fixed bug, not a missing feature.
- **OTLP redirect following** (OTLP-11): `handle_redirect` is a literal no-op; the exporter retries against the original URI, never the `Location` header — same defect class as the Metrics OTLP exporter.
- **OTLP partial-success handling** (OTLP-13): `ExportLogsServiceResponse.partial_success` is decoded nowhere.
- **OTLP `schema_url` on Resource/Scope** (OTLP-14): never set, because the underlying `Resource`/`InstrumentationScope` classes don't carry the field at all.
- **Event-to-span-event bridge processor** (SDK-41, Development): entirely absent.
- **`LoggerConfigurator`/`LoggerConfig`** (SDK-7, SDK-10, SDK-15 through SDK-19, SDK-22, SDK-24, Development): no `enabled`/`minimum_severity`/`trace_based` filtering exists anywhere.
- **SDK self-observability** (SDK-51, Development).

### Stable — partial / behavioral deviations

- **Discard-logging for attribute limits** (SDK-31): the count-limit path never logs a discard message at all; the validity-check path logs once *per invalid attribute* instead of once per `LogRecord` — both directions of the same requirement are wrong, just in opposite ways.
- **`ObservedTimestamp` default disagreement between layers** (SDK-20): `Logger#on_emit`'s keyword default is `Time.now` (spec-correct), but `LogRecord#initialize` itself falls back to a caller-supplied `timestamp` before `Time.now` — the two entry points don't agree on which spec reading to satisfy.
- **`BatchLogRecordProcessor` holds a live `LogRecord` reference, not a clone** (SDK-29, SDK-34): the spec makes concurrent-safety and cloning optional, but Ruby offers neither a deep-clone operation nor any mitigation for the exact mutation race the spec calls out by name.
- **`SimpleLogRecordProcessor#shutdown`/`#force_flush` return `nil` instead of a status constant when already stopped** (SDK-36): a minor status-reporting deviation.
- **`ConsoleLogRecordExporter` and the OTLP exporter aren't internally concurrency-safe for `ForceFlush`/`Shutdown`** (SDK-42, SDK-50): no mutex protects `@stopped`/`@shutdown`, relying entirely on callers not to race — `InMemoryLogRecordExporter` is the only one that actually guards this.
- **OTLP root-path normalization missing for bare per-signal endpoints** (OTLP-2): `URI('http://host:port').path` is `''`, not `/`, and nothing corrects it before building the HTTP request.
- **OTLP `TraceFlags` encoding is type-fragile** (OTLP-15): works for the auto-derived `TraceFlags` object case, silently produces `nil` for a caller-supplied raw `Integer`, which is what the SDK's own documentation says the field's type should be.
- **No OTLP gRPC transport** (OTLP-8): HTTP/protobuf-only satisfies the "at least one" MUST, but not the "SHOULD support both" bar.
- **Request/response size limits unenforced** (OTLP-7): matches every other language in the org-wide matrix, so not a Ruby-specific regression, but still an open Stable gap.
- **`Logger` instances aren't language-enforced to be `LoggerProvider`-only** (SDK-3): `Logger.new` is a public constructor, restricted only by a docstring comment.

### Development — missing entirely (upstream still in flux; lower urgency)

- **`LoggerConfigurator`/`LoggerConfig`** (SDK-7 through SDK-19, SDK-22, SDK-24) — covered above; repeated here because it's the single largest block of Development-status gaps in this signal.
- **Event-to-span-event bridge** (SDK-41).
- **SDK self-observability** (SDK-51).
- **Ergonomic API** (API-15) — no event-semantics-friendly convenience layer over the base Logs API.

---
