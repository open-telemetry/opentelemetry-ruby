# Logs Spec Compliance

This document tracks how the Ruby `logs_api`, `logs_sdk`, and `exporter/otlp-logs` gems align with
the [OpenTelemetry Logs specification](https://github.com/open-telemetry/opentelemetry-specification/tree/main/specification/logs)
as of 2026-10-12 (re-checked against `open-telemetry/opentelemetry-ruby` `upstream/main` @ `ad8eaf25d`; first written 2026-08-19).
It follows the same methodology as `SPEC_COMPLIANCE_METRICS.md`. Work tracked by the
[Logs: Stability Prep milestone](https://github.com/open-telemetry/opentelemetry-ruby/milestone/12)
is summarized in [Milestone tracker](#milestone-tracker-logs-stability-prep).

> **Re-verification note (2026-10-12):** rows whose status or notes changed in this pass were re-read against
> current code. Line numbers in rows that were not touched were *not* all re-checked and may have drifted
> (notably anything pointing into `exporter/otlp-logs/.../logs_exporter.rb`, whose encoding moved to
> `exporter/otlp-common` in #2434).

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
- **Status legend**: ✅ Full · ⚠️ Partial · ❌ Missing · 🚧 In progress (an open PR that may resolve it; **not**
  yet compliant — the row stays non-compliant until the PR merges) · N/A Not applicable to this implementation.
- Every citation below was read directly from the referenced file/line; none are taken on faith from
  a summary.

---

## API (`api.md`)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| API-1 | API SHOULD provide a way to set/register and access a global default `LoggerProvider`. | Stable | ⚠️ | Since #2415 (merged 2026-10-05, breaking) the provider slot lives on `OpenTelemetry::Internal` (`@api private`) and the public `OpenTelemetry.logger_provider`/`logger_provider=` accessors are defined only in `logs_api/lib/opentelemetry/logs/global.rb`, which `opentelemetry-logs-sdk` requires and `opentelemetry-logs-api` alone does not (`logs_api/lib/opentelemetry-logs-api.rb`). With the SDK installed the requirement is met (backed by `Internal::ProxyLoggerProvider`); an API-only consumer has no public accessor. Deliberate while the Logs API is unstable; no milestone issue tracks revisiting it. |
| API-2 | `LoggerProvider` MUST provide a "Get a Logger" operation. | Stable | ✅ | `logs_api/lib/opentelemetry/logs/logger_provider.rb:20-22`; SDK override `logs_sdk/lib/opentelemetry/sdk/logs/logger_provider.rb:44-55`. |
| API-3 | Get a Logger MUST accept `name`. | Stable (`api.md:68-81`) | ✅ | Both layers accept `name` (API positional, SDK required keyword). |
| API-4 | Get a Logger MUST accept optional `version`. | Stable (`api.md:83-84`) | ✅ | `logger_provider.rb` (API) `:20` and (SDK) `:44` both default `version` to `nil`/`''`. |
| API-5 | Get a Logger MUST accept optional `schema_url`. | Stable (`api.md:86-87`) | ❌ | **Not in milestone 12.** Tracked only by umbrella #2380 (open, stale, labelled `logs`) with #2381 (InstrumentationScope) and #2382 (Resources). Open PRs #1237 (open, review required) and #2402 (draft) add `schema_url` for Tracers/Resources and touch no logs files; #1719 covers Metrics only — so **no pending fix for Logs**. Neither the no-op `LoggerProvider#logger` (`logs_api/.../logger_provider.rb:20`) nor the SDK's (`logs_sdk/.../logger_provider.rb:44`) accept a `schema_url` parameter at all — it's silently unsupported. Consistent with the org-wide `spec-compliance-matrix.md` leaving Ruby's Tracer/Meter `schema_url` cells blank too; `InstrumentationScope` itself (`sdk/lib/opentelemetry/sdk/instrumentation_scope.rb`) carries no `schema_url` field anywhere in this SDK. |
| API-6 | Get a Logger MUST accept a variable number of instrumentation-scope `attributes`, including none. | Stable (`api.md:89-91`) | ❌ | **Tracked: #2346** (milestone 12; no linked PR). No `attributes:` parameter on either `logger_provider.rb` (API `:20` or SDK `:44`); `InstrumentationScope` gained an `attributes` member in #2094 (`sdk/lib/opentelemetry/sdk/instrumentation_scope.rb`), but `InstrumentationScope.new(name, version)` (`logs_sdk/.../logger.rb:25`) never sets it. Also, the shared OTLP encoder emits only `name`/`version` for the scope, so scope attributes would not reach the wire even once accepted (see OTLP-14). |
| API-7 | `Logger` MUST provide a function to Emit a `LogRecord`. | Stable (`api.md:101-103`) | ✅ | `logs_api/lib/opentelemetry/logs/logger.rb:44-57` `#on_emit`; SDK `logs_sdk/.../logger.rb:66-92`. |
| API-8 | `Logger` SHOULD provide functions to report if `Logger` is `Enabled`. | Stable (`api.md:105-107`) | ❌ | **Tracked: #2348** (milestone 12; no linked PR). No `enabled?`/`enabled` method exists on `OpenTelemetry::Logs::Logger` (`logs_api/lib/opentelemetry/logs/logger.rb`, the class only defines `on_emit`) nor on the SDK `Logger` (`logs_sdk/.../logger.rb`) — confirmed by reading both files in full. This is one of the largest gaps in the whole signal; see SDK-25 below for the SDK-side consequences. |
| API-9 | Emit a LogRecord MUST accept: Timestamp, ObservedTimestamp, Context (optional-if-implicit-context-supported, else required; MUST use current Context if unspecified), SeverityNumber, SeverityText, Body, Attributes, EventName (all optional). | Stable (`api.md:113-125`) | ✅ | `logs_api/lib/opentelemetry/logs/logger.rb:44-56` declares every one of these as an optional keyword arg including `context: nil`; SDK `logs_sdk/.../logger.rb:66-76` defaults `context: OpenTelemetry::Context.current` (satisfies "MUST use current Context if unspecified", `api.md:118-120`). |
| API-10 | API MAY accept an optional Exception parameter. | Stable (`api.md:127-129`) | ❌ | **Tracked: #2349** (milestone 12; no linked PR). Optional (MAY) feature, so its absence is not a non-conformance by itself. No `exception:` parameter anywhere in either `Logger#on_emit` signature (API or SDK) — there is no code path for exception-derived attributes at all (ties to SDK-22 below). |
| API-11 | Enabled SHOULD accept Context (same implicit/explicit rule as Emit), SeverityNumber, EventName; MUST return a language-idiomatic boolean; documentation SHOULD state Enabled is optional and its value isn't static. | Stable (`api.md:136-157`) | ❌ | Moot — there is no `Enabled` method to accept these params at all (API-8). |
| API-12 | For each optional parameter the API MUST accept it but MUST NOT obligate the user to supply it; for required parameters the API MUST obligate the user. | Stable (`api.md:164-168`) | ✅ | Every optional param across both API layers has a default value; SDK's `logger(name:, ...)` makes `name` a required keyword with no default (`logs_sdk/.../logger_provider.rb:44`), matching `name` being the one required Get-a-Logger param. |
| API-13 | `LoggerProvider` — all methods MUST be documented as safe for concurrent use by default. | Stable (`api.md:175-176`) | ✅ | SDK `LoggerProvider` guards `@registry`/`@log_record_processors`/`@stopped` with `@registry_mutex`/`@mutex` (`logs_sdk/.../logger_provider.rb:31,35,52,63,86,117`); no-op `LoggerProvider` (`logs_api/.../logger_provider.rb`) is a trivial memoized no-op. |
| API-14 | `Logger` — all methods MUST be documented as safe for concurrent use by default. | Stable (`api.md:178-179`) | ✅ | SDK `Logger#on_emit` (`logs_sdk/.../logger.rb:66-92`) holds no mutable instance state of its own; all shared state is delegated to the mutex-guarded `LoggerProvider`. |
| API-15 | Ergonomic API MAY be additionally provided; SHOULD support event semantics; SHOULD be idiomatic. | Development (`api.md:181-190`) | ❌ | **Tracked: #2347** (milestone 12; no linked PR). MAY + Development. No ergonomic/event-focused API layered on top of `logs_api`/`logs_sdk` (confirmed no such module in either gem). Matches the org-wide matrix's blank "Ergonomic API" cell for Ruby. |

## No-Op (`noop.md`)

Only what's distinct from the API table above (per the Metrics doc's own convention for this section).

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| NOOP-1 | No-Op MUST allow creation of multiple `LoggerProvider`s holding no state, safe for concurrent use, never erroring/logging; MAY return the same instance/Logger to every creation request. | Stable (`noop.md:30-51`) | ✅ | `logs_api/lib/opentelemetry/logs/logger_provider.rb:11,20-22` — `NOOP_LOGGER` is a single memoized singleton returned regardless of `name`/`version` (`@logger \|\|= NOOP_LOGGER`), which the spec explicitly permits (`noop.md:41-42,50-51`). No error paths exist. |
| NOOP-2 | No-Op operations MUST accept all defined parameters, MUST NOT validate them, MUST NOT error/log. | Stable (`noop.md:33-35`) | ⚠️ | Holds for the params the no-op layer *does* declare (`logs_api/.../logger.rb:44-56`, `logger_provider.rb:20`) — none are validated. But per API-5/API-6, `schema_url` and `attributes` aren't even declared as parameters to accept-without-validating in the first place, so this requirement can't be fully satisfied. |
| NOOP-3 | No-Op `Logger` MUST allow emitting LogRecords. | Stable (`noop.md:57-58`) | ✅ | `logs_api/lib/opentelemetry/logs/logger.rb:44-57` — empty-bodied `on_emit`. |
| NOOP-4 | No-Op Enabled MUST always return `false`. | Stable (`noop.md:62`) | ❌ | **Tracked: #2348.** There is no `Enabled` method on the no-op `Logger` to return anything — calling `.enabled?`/`.enabled` on a fresh `OpenTelemetry::Logs::Logger` raises `NoMethodError` instead of behaving as a spec-compliant no-op. Direct consequence of API-8's absence. |

## SDK (`sdk.md`)

### LoggerProvider

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-1 | `LoggerProvider` MUST allow a `Resource` to be specified; SHOULD associate it with all `LogRecord`s from any `Logger`. | Stable (`sdk.md:61-63`) | ✅ | `logs_sdk/lib/opentelemetry/sdk/logs/logger_provider.rb:28,32` (`resource:` param, `@resource`), threaded into every emitted record via `on_emit` (`:147-159`, `resource: @resource`). |
| SDK-2 | SDK SHOULD allow creation of multiple independent `LoggerProvider`s. | Stable (`sdk.md:67`) | ✅ | `LoggerProvider#initialize` (`logger_provider.rb:28-36`) has no shared/global state between instances. |
| SDK-3 | It SHOULD only be possible to create `Logger`s through a `LoggerProvider`. | Stable (`sdk.md:71-72`) | ⚠️ | **Tracked: #2350** (milestone 12; no linked PR; SHOULD). Enforced only by convention/documentation (`logs_sdk/lib/opentelemetry/sdk/logs/logger.rb:14-16` docstring "This should not be called directly") — `Logger.new(name, version, logger_provider)` is a fully public constructor with no visibility restriction, so nothing in the language actually prevents direct instantiation. |
| SDK-4 | `LoggerProvider` MUST implement the Get-a-Logger API. | Stable (`sdk.md:74`) | ✅ | `logger_provider.rb:44-55`. (Inherits the `schema_url`/`attributes` gaps from API-5/API-6.) |
| SDK-5 | User input MUST be used to create an `InstrumentationScope` stored on the `Logger`. | Stable (`sdk.md:76-78`) | ✅ | `logs_sdk/.../logger.rb:25` `@instrumentation_scope = InstrumentationScope.new(name, version)`. |
| SDK-6 | Invalid (null/empty) `name` MUST still return a working `Logger` fallback (not null/exception); its name SHOULD keep the original invalid value; SHOULD log a warning. | Stable (`sdk.md:80-83`) | ✅ | `logger_provider.rb:47-50` warns "invalid name" but still proceeds to `Logger.new(name, ...)` (`:53`) with the original value untouched. |
| SDK-7 | **[Development]** `LoggerProvider` MUST compute the `LoggerConfig` via a configured `LoggerConfigurator` and create Loggers that conform to it. | Development (`sdk.md:85-88`) | ❌ | **Untracked** (no issue; Development) — proposed in `new-logs-issues.json`. No `LoggerConfigurator`/`LoggerConfig` class exists anywhere in `logs_sdk` (confirmed by reading every file under `logs_sdk/lib`). |
| SDK-8 | Configuration (`LogRecordProcessor`s and, Development, `LoggerConfigurator`) MUST be owned by the `LoggerProvider`; MAY be applied at creation time. | Stable (`sdk.md:92-95`) | ⚠️ | Processors are owned by `LoggerProvider` (`@log_record_processors`, `logger_provider.rb:29`) — ✅ for that half. `LoggerConfigurator` doesn't exist (SDK-7) — ❌ for that half. |
| SDK-9 | If configuration is updated (e.g. adding a processor), the update MUST also apply to all already-returned `Logger`s. | Stable (`sdk.md:97-99`) | ✅ | `add_log_record_processor` (`logger_provider.rb:62-71`) mutates the shared `@log_record_processors` array; every `Logger` routes emission back through the same `LoggerProvider#on_emit` (`:161`), which reads that array live — no per-`Logger` snapshot exists to go stale. |
| SDK-10 | **[Development]** `LoggerConfigurator`: function accepting `logger_scope`, returning a `LoggerConfig` or a default-signal; called on Logger creation and on every outstanding Logger when the configurator updates. | Development (`sdk.md:112-126`) | ❌ | Doesn't exist (SDK-7). |
| SDK-11 | `Shutdown` MUST be called only once per `LoggerProvider`; after it, subsequent Get-a-Logger calls are not allowed and SHOULD return a no-op `Logger`. | Stable (`sdk.md:142-144`) | ✅ | Fixed by #2452 (merged 2026-10-12, `ad8eaf25d`; not yet in checkouts at `b39632863` or earlier). `LoggerProvider#logger` now checks `@stopped`, warns, and returns `OpenTelemetry::Logs::Logger.new` (the no-op `Logger`); the "called only once" half is enforced by `shutdown` (warns and returns `FAILURE` on a second call). Previously ⚠️. |
| SDK-12 | `Shutdown` SHOULD report succeeded/failed/timed-out; SHOULD complete/abort within a timeout. | Stable (`sdk.md:146-152`) | ✅ | Returns `Export::SUCCESS`/`FAILURE`/`TIMEOUT` (`logger_provider.rb:89,95,101`), tracks remaining timeout across processors via `OpenTelemetry::Common::Utilities.maybe_timeout` (`:92-98`). |
| SDK-13 | `Shutdown` MUST invoke `Shutdown` on all registered `LogRecordProcessor`s. | Stable (`sdk.md:154-155`) | ✅ | `logger_provider.rb:93-98`. |
| SDK-14 | `ForceFlush` MUST invoke `ForceFlush` on all registered `LogRecordProcessor`s; SHOULD report status/timeout. | Stable (`sdk.md:159-175`) | ✅ | `logger_provider.rb:116-130`, mutex-guarded, per-processor timeout budgeting, `SUCCESS` if already stopped (`:118`). |

### Logger / LoggerConfig (Development)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-15 | `Logger` MUST behave per the `LoggerConfig` computed at creation, and MUST update if the `LoggerConfigurator` updates. | Development (`sdk.md:179-183`) | ❌ | No `LoggerConfig` concept exists (SDK-7). |
| SDK-16 | `LoggerConfig.enabled`: defaults to `true`; when `false`, `Logger` MUST behave like the No-Op Logger. | Development (`sdk.md:192-198`) | ❌ | Not implemented. |
| SDK-17 | `LoggerConfig.minimum_severity`: defaults to `0`; log records with a specified (non-zero) severity below it MUST be dropped; unspecified-severity records bypass this filter. | Development (`sdk.md:200-208`) | ❌ | Not implemented — no severity-threshold filtering anywhere in `logs_sdk`. |
| SDK-18 | `LoggerConfig.trace_based`: defaults to `false`; when `true`, log records associated with an unsampled trace (valid `SpanId`, `TraceFlags` SAMPLED unset) MUST be dropped. | Development (`sdk.md:210-222`) | ❌ | Not implemented. |
| SDK-19 | Changes to `LoggerConfig` params don't need to be immediately visible to `Enabled` callers but MUST be eventually visible. | Development (`sdk.md:224-226`) | N/A | Moot — no `LoggerConfig` exists to have visibility semantics. |

### Emit a LogRecord / Enabled

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-20 | If ObservedTimestamp is unspecified, the implementation SHOULD set it equal to the current time. | Stable (`sdk.md:230-231`) | ⚠️ | Through the public `Logger#on_emit` path (`logs_sdk/.../logger.rb:67`), the keyword default `observed_timestamp: Time.now` is evaluated at call time, so an unspecified value does become "now" — ✅ at that entry point. But `SDK::Logs::LogRecord#initialize` itself (`logs_sdk/.../log_record.rb:80`) computes `observed_timestamp \|\| timestamp \|\| Time.now` — i.e. it prefers a caller-supplied `timestamp` over "current time" when constructed directly (as `LoggerProvider#on_emit` and any direct `LogRecord.new` caller do) — a different rule than the literal `sdk.md:230-231` text (though it does match the *description* of the field itself, `data-model.md:192-198`, which says the two are typically equal at generation time). Net: the two code paths disagree with each other on which reading of the spec to satisfy. #2451 (merged 2026-10-10) added a code comment recording the `timestamp` fallback as a deliberate choice following the data model's note; no issue tracks changing it, so this stays ⚠️ as a documented, low-severity deviation. |
| SDK-21 | If an Exception is provided, the SDK MUST by default set exception-semconv attributes on the `LogRecord`; user-provided attributes MUST take precedence and MUST NOT be overwritten. | Stable (`sdk.md:233-237`) | N/A | **Tracked: #2349** (milestone 12; no linked PR). Conditional on the optional API-10 parameter ("*If* an Exception is provided"): Ruby offers no way to provide one, so the MUST is not currently triggered. Previously ❌ — overstated. Becomes ✅/❌ the moment API-10 is implemented, so #2349 must deliver both halves together. |
| SDK-22 | **[Development]** Before processing, filtering rules from `LoggerConfig` (Enabled, minimum-severity, trace-based) MUST be applied. | Development (`sdk.md:244-259`) | ❌ | Not implemented (depends on SDK-16/17/18). |
| SDK-23 | `Enabled` MUST return `false` when there are no registered `LogRecordProcessor`s, or when all registered processors implement `Enabled` and all return `false`; otherwise SHOULD return `true`. | Stable (`sdk.md:263-265,274-277`) | ❌ | **Tracked: #2348.** There is no `Enabled` method on the SDK `Logger` at all (confirmed: `logs_sdk/lib/opentelemetry/sdk/logs/logger.rb` defines only `initialize`/`on_emit`) — this Stable MUST is entirely unimplemented, not merely partial. |
| SDK-24 | **[Development]** `Enabled` MUST also return `false` per `LoggerConfig.enabled`/`minimum_severity`/`trace_based`. | Development (`sdk.md:266-273`) | ❌ | Moot — SDK-23's prerequisite doesn't exist either. |

### ReadableLogRecord / ReadWriteLogRecord

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-25 | `ReadableLogRecord` MUST expose all information added to the `LogRecord`, plus (implicitly) `InstrumentationScope` and `Resource`. | Stable (`sdk.md:286-290`) | ✅ | `logs_sdk/.../log_record.rb:16-27` — every field is an `attr_accessor`, including `resource` and `instrumentation_scope`. |
| SDK-26 | Trace context fields MUST be populated from the resolved `Context` when emitted. | Stable (`sdk.md:292-294`) | ✅ | `logs_sdk/.../logger.rb:77-89` — pulls `trace_id`/`span_id`/`trace_flags` from `OpenTelemetry::Trace.current_span(context)` whenever the caller didn't supply them explicitly. |
| SDK-27 | Counts for attributes dropped due to collection limits MUST be available to exporters. | Stable (`sdk.md:296-299`) | ✅ | `LogRecord` now tracks `@dropped_attributes_count` directly (incremented in `truncate_attributes`), carried into `LogRecordData#dropped_attributes_count` (`log_record_data.rb`) and encoded by `exporter/otlp-common/.../common.rb` `as_otlp_log_record`. Caveat: only count-limit truncations are counted — attributes dropped by validation are not (see SDK-31). |
| SDK-28 | `ReadWriteLogRecord` MUST additionally allow modifying Timestamp, ObservedTimestamp, SeverityText, SeverityNumber, Body, Attributes, TraceId, SpanId, TraceFlags, EventName. | Stable (`sdk.md:309-321`) | ✅ | All ten are plain `attr_accessor`s on `SDK::Logs::LogRecord` (`log_record.rb:16-27`) — fully mutable pre-export. |
| SDK-29 | SDK MAY provide a deep-clone operation for `ReadWriteLogRecord`, for use by concurrent processors. | Stable, MAY (`sdk.md:323-326`) | ❌ | No clone/dup override or explicit deep-clone method on `SDK::Logs::LogRecord` (`log_record.rb`). Low severity (MAY), but see SDK-40 below for the concrete consequence in `BatchLogRecordProcessor`. |

### LogRecord Limits

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-30 | `LogRecord` attributes MUST adhere to the common attribute-limit rules; if implemented, the SDK MUST provide a way to change the limits via `LoggerProvider` configuration; options MAY be bundled as `LogRecordLimits`. | Stable (`sdk.md:330-338`) | ✅ | `logs_sdk/lib/opentelemetry/sdk/logs/log_record_limits.rb` — a dedicated `LogRecordLimits` class, injected via `LoggerProvider.new(log_record_limits:)` (`logger_provider.rb:28`). Defaults match the common-attribute-limits spec exactly: `attribute_count_limit` reads `OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT` → `OTEL_ATTRIBUTE_COUNT_LIMIT` → **128** (`log_record_limits.rb:22-26`); `attribute_length_limit` reads `OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT` → `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` → **no limit** (`:27-30`) — confirmed against `specification/configuration/sdk-environment-variables.md:203-204`. |
| SDK-31 | SHOULD log a message when an attribute is discarded due to a limit; the message MUST be printed at most once per `LogRecord` (not per discarded attribute). | Stable (`sdk.md:354-357`) | 🚧 | **Tracked: #2351** (milestone 12) ← **PR #2394, open, non-draft, APPROVED** (2 approvals; closes #2351 via `Fixes #2351`). **Pending, not merged**: the PR is `CONFLICTING`/`DIRTY` against `main` (its base `57d48c9` predates the `@dropped_attributes_count` tracking in `truncate_attributes`, so the rebase must keep that counter) and its last CI run (2026-09-29) failed the `opentelemetry-exporter-otlp-logs` jobs on all three OSes (logs-api/logs-sdk passed; cause not investigated). Current `main` behavior: (1) the count-**truncation** path (`log_record.rb` `truncate_attributes`) logs **nothing**; (2) `validate_attributes` calls `return false` from *inside* the `keep_if` block, which exits the whole method on the **first** invalid attribute — so it logs **at most one** message (an earlier version of this row wrongly said one-per-invalid-attribute), but also **does not drop that invalid attribute and never validates the remaining ones**. #2394 fixes all three (single `Discarded N log record attributes…` summary; invalid attributes actually dropped) — but see "Issue accuracy review" for scope caveats. |

### LogRecordProcessor

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-32 | Processors registered on `LoggerProvider` MUST be invoked in the order registered. | Stable (`sdk.md:367-368`) | ✅ | `add_log_record_processor` appends (`logger_provider.rb:69`); `on_emit` iterates with `.each` in that same order (`:161`). |
| SDK-33 | SDK MUST allow each pipeline to end with an individual exporter; MUST allow custom processors and decorating built-ins. | Stable (`sdk.md:371-376`) | ✅ | `LogRecordProcessor` is an explicitly duck-typed interface (`log_record_processor.rb:10-13`); `Simple`/`BatchLogRecordProcessor` each take one `exporter`; any object satisfying the 3-method interface can be registered. |
| SDK-34 | `OnEmit` is called synchronously on the emitting thread; SHOULD NOT block or throw. `logRecord` mutations MUST be visible to subsequently-registered processors. A processor MAY freely modify `logRecord` during the call; concurrent-safety of `ReadWriteLogRecord` is OPTIONAL, and implementations SHOULD recommend a clone for concurrent processing. | Stable (`sdk.md:404-425`) | ⚠️ | Synchronous call + mutation-visibility ✅: `logger_provider.rb:161` passes the **same** `LogRecord` object reference to every processor in turn, so processor A's edits are visible to processor B. `SimpleLogRecordProcessor#on_emit` also rescues all exceptions (`export/simple_log_record_processor.rb:49-50`), satisfying "SHOULD NOT throw" defensively. But `BatchLogRecordProcessor#on_emit` (`export/batch_log_record_processor.rb:70-83`) enqueues the **live** `LogRecord` object for asynchronous export later by the background thread — it never clones it (ties to SDK-29's missing clone operation) — so a caller that mutates the record after `on_emit` returns can race with the background thread's later `.to_log_record_data` call. The spec makes this optional to guard against, but doesn't recommend a clone anywhere in this code path either. |
| SDK-35 | `Enabled` MAY be implemented on a `LogRecordProcessor`, returning `false` if a would-be `LogRecord` should be filtered; MUST default to `true` for indeterminate state; wrapping processors' `OnEmit` should never call the wrapped processor's `Enabled`. | Stable, MAY (`sdk.md:429-464`) | ❌ | No `enabled` method on the base `LogRecordProcessor` (`log_record_processor.rb`) or either built-in processor. Low severity (MAY) but compounds the Logger-level `Enabled` absence (SDK-23) — there's no filtering fast-path anywhere in the pipeline. |
| SDK-36 | `Shutdown` SHOULD be called once; subsequent `OnEmit` calls are not allowed and SHOULD be ignored gracefully; SHOULD report status; MUST include the effects of `ForceFlush`. | Stable (`sdk.md:471-478`) | ⚠️ | Post-shutdown `OnEmit` is correctly a no-op in both built-ins (`simple_log_record_processor.rb:46`, `batch_log_record_processor.rb:71`, both `return if @stopped`). `BatchLogRecordProcessor#shutdown` explicitly calls `force_flush` (`:149`) ✅. `SimpleLogRecordProcessor#shutdown`/`#force_flush` (`simple_log_record_processor.rb:65-83`) `return if @stopped` with **no explicit return value** (i.e. `nil`) instead of one of `SUCCESS`/`FAILURE`/`TIMEOUT` when called on an already-stopped processor — a minor status-reporting deviation. **Untracked** — proposed in `new-logs-issues.json`. (Re-verified 2026-10-12: unchanged.) |
| SDK-37 | `ForceFlush` is a hint to complete pending export tasks ASAP; built-in processors MUST try to `Export` all pending records then `ForceFlush` the exporter; MUST prioritize honoring a specified timeout. | Stable (`sdk.md:487-499`) | ✅ | `BatchLogRecordProcessor#force_flush` (`export/batch_log_record_processor.rb:96-129`) drains the queue in batches, exports each, then calls `@exporter.force_flush` (`:113`), returning `TIMEOUT` as soon as the budget is exhausted (`:106`) and re-queueing any unexported remainder (`:114-128`). `SimpleLogRecordProcessor#force_flush` delegates straight to the exporter (`:68`) — trivially compliant since every record was already exported synchronously at `on_emit` time. |
| SDK-38 | Both a Simple and a Batching processor MUST be provided by the standard SDK. | Stable (`sdk.md:516-517`) | ✅ | `export/simple_log_record_processor.rb`, `export/batch_log_record_processor.rb`. |
| SDK-39 | Simple processor MUST synchronize calls to the exporter's `Export` so they're never concurrent; configurable param: `exporter`. | Stable (`sdk.md:533-538`) | ✅ | Single-threaded synchronous call at `on_emit` time (`export/simple_log_record_processor.rb:48`) — nothing else can call `Export` concurrently through this processor. |
| SDK-40 | Batching processor MUST synchronize `Export` calls; params: `exporter`, `maxQueueSize` (default 2048), `scheduledDelayMillis` (default 1000), `exportTimeoutMillis` (default 30000), `maxExportBatchSize` (default 512, must be ≤ `maxQueueSize`). | Stable (`sdk.md:546-559`) | ✅ | `export/batch_log_record_processor.rb:37-46` — exact defaults (`OTEL_BLRP_EXPORT_TIMEOUT`→30000, `OTEL_BLRP_SCHEDULE_DELAY`→1000, `OTEL_BLRP_MAX_QUEUE_SIZE`→2048, `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE`→512), with an `ArgumentError` guard (`:43-46`) enforcing `max_export_batch_size <= max_queue_size`. `@export_mutex.synchronize` around every `@exporter.export` call (`:186`) serializes exports. |
| SDK-41 | **[Development]** Event-to-span-event bridge: MUST convert qualifying LogRecords (non-empty EventName, valid TraceId/SpanId, current span recording, matching IDs) into exactly one span event with mapped name/timestamp/attributes; MUST NOT block the record's normal pipeline; no configurable params. | Development (`sdk.md:561-600`) | ❌ | **Tracked: #2352** (milestone 12; no linked PR; Development). No such processor exists anywhere in `logs_sdk` (confirmed by directory listing — no bridge-related file). |

### LogRecordExporter

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-42 | Each `LogRecordExporter` implementation MUST document its concurrency characteristics. | Stable (`sdk.md:612-613`) | ⚠️ | **Tracked: #2353** (milestone 12; no linked PR). #2450 (merged) added a debugging-only warning to the Console exporter's docs but still no concurrency statement. `InMemoryLogRecordExporter` is internally mutex-protected and its class docs imply test-safety (`export/in_memory_log_record_exporter.rb:39,47,69,94`). Neither `ConsoleLogRecordExporter` (`export/console_log_record_exporter.rb`) nor the OTLP `LogsExporter` (`exporter/otlp-logs/.../logs_exporter.rb`) document (or possess) any concurrency guarantee for concurrent `export`/`shutdown` calls on the same instance. |
| SDK-43 | `Export` should not be called concurrently with itself for the same exporter instance. | Stable (`sdk.md:625-626`) | ✅ | Enforced at the call site: `BatchLogRecordProcessor#export_batch` wraps every `@exporter.export` call in `@export_mutex.synchronize` (`export/batch_log_record_processor.rb:186`), and `SimpleLogRecordProcessor` only ever calls `export` synchronously from the single emitting thread. The exporters themselves add no independent protection (see SDK-42), but nothing in this codebase's own pipelines calls `Export` concurrently on one instance. |
| SDK-44 | `Export` MUST NOT block indefinitely — a reasonable timeout MUST apply. | Stable (`sdk.md:635-636`) | ✅ | OTLP: per-attempt `@http.open_timeout`/`read_timeout`/`write_timeout` set from the remaining timeout budget every call (`exporter/otlp-logs/.../logs_exporter.rb:166-168`, reset in `ensure` at `:231-234`). Console/InMemory are synchronous in-process operations with nothing to block on. |
| SDK-45 | Concurrent requests and retry logic are the exporter's responsibility; built-in `LogRecordProcessor`s SHOULD NOT implement retry. | Stable (`sdk.md:638-640`) | ✅ | Neither `SimpleLogRecordProcessor` nor `BatchLogRecordProcessor` retries a failed export; the OTLP exporter implements its own retry/backoff (see OTLP-16 below). |
| SDK-46 | `ForceFlush` is a hint to complete pending exports ASAP; SHOULD report status; SHOULD only be called when absolutely necessary; SHOULD honor a timeout. | Stable (`sdk.md:669-682`) | ✅ | All three shipped exporters implement `force_flush` returning `SUCCESS` (`export/console_log_record_exporter.rb:27-29`, `export/in_memory_log_record_exporter.rb:83-85`, `exporter/otlp-logs/.../logs_exporter.rb:99-101`) — trivially correct since none of them buffer data internally between `export` calls. |
| SDK-47 | `Shutdown` SHOULD be called once; after it, `Export` is not allowed and SHOULD return `Failure`; `Shutdown` SHOULD NOT block indefinitely. | Stable (`sdk.md:690-694`) | ✅ | Base `LogRecordExporter#shutdown`/`#export` (`export/log_record_exporter.rb:30-34,50-53`) — `@stopped` gate returns `FAILURE` post-shutdown. Same pattern independently re-implemented and confirmed in `ConsoleLogRecordExporter` (`:19-20,31-34`), `InMemoryLogRecordExporter` (`:70,93-99`), and the OTLP `LogsExporter` (`@shutdown` flag, `logs_exporter.rb:88-90,108-112`) — all four exporters correctly block post-shutdown exports. |

### Concurrency requirements / Self-observability

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| SDK-48 | `LoggerProvider`: Logger creation, `ForceFlush`, `Shutdown` MUST be safe for concurrent calls. | Stable (`sdk.md:707-708`) | ✅ | `logger_provider.rb` uses `@registry_mutex` for `#logger` (`:52`) and `@mutex` for `#shutdown`/`#force_flush`/`#add_log_record_processor` (`:63,86,117`). |
| SDK-49 | `Logger`: all methods MUST be safe for concurrent calls. | Stable (`sdk.md:710`) | ✅ | `logs_sdk/.../logger.rb` holds no mutable instance state beyond values fixed at construction (`@instrumentation_scope`, `@logger_provider`); real work is delegated to the mutex-guarded `LoggerProvider`. |
| SDK-50 | `LogRecordExporter`: `ForceFlush` and `Shutdown` MUST be safe for concurrent calls. | Stable (`sdk.md:712-713`) | ⚠️ | **Tracked: #2353.** `InMemoryLogRecordExporter` guards both with `@mutex` (`export/in_memory_log_record_exporter.rb:83-85,93-99`) ✅. `ConsoleLogRecordExporter#force_flush`/`#shutdown` (`:27-34`) have no synchronization at all around the `@stopped` flag. The OTLP exporter's `#shutdown` (`logs_exporter.rb:108-112`) likewise mutates `@shutdown`/calls `@http.finish` with no mutex — a concurrent `shutdown` racing an in-flight `export`'s use of `@http` is not guarded against anywhere in this file. |
| SDK-51 | **[Development]** Logs SDK SHOULD support SDK self-observability. | Development (`sdk.md:719`) | ❌ | **Untracked** (Development) — proposed in `new-logs-issues.json`. No self-observability instrumentation anywhere in `logs_sdk` (no `otel.sdk.*` metrics of any kind, confirmed by inspection of every file in `logs_sdk/lib`). |

---

## Data Model (`data-model.md`)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| DM-1 | `Body` MUST support `AnyValue` to preserve the semantics of structured logs. | Stable (`data-model.md:399-400`) | ✅ | **Re-assessed 2026-10-12 (previously ⚠️); related issue #2354 is partly inaccurate — see "Issue accuracy review".** `SDK::Logs::LogRecord#body` stores any Ruby value; the shared encoder's `as_otlp_any_value` (`exporter/otlp-common/lib/opentelemetry/exporter/otlp/common.rb`, moved there by #2434) maps `String`/`Integer`/`Float`/`true`/`false`/`Array`/`Hash` to the matching `AnyValue` variant. `nil` encodes as an unset (empty) `AnyValue`, which is exactly how `common/README.md:52-53,61-63` says an *empty value* (`nil` in Ruby) is represented and MUST be passed on — not data loss. The only residual quirk is Ruby types outside `AnyValue` (`Symbol`, `Time`, `BigDecimal`…), which the spec does not define behavior for; they also encode as empty. |
| DM-2 | If `SpanId` is present, `TraceId` SHOULD also be present. | Stable (`data-model.md:222-223`) | N/A | A data-quality guideline for whoever populates the fields, not an SDK-enforceable invariant — `LogRecord#initialize` (`log_record.rb:72-73,86-87`) stores `trace_id`/`span_id` independently with no cross-field validation, which is consistent with how this class of SHOULD is typically left to callers rather than the SDK. |
| DM-3 | `SeverityNumber=0` MAY represent an unspecified value. | Stable (`data-model.md:271`) | ✅ | `logs_api/lib/opentelemetry/logs/severity_number.rb:10` `SEVERITY_NUMBER_UNSPECIFIED = 0`. |
| DM-4 | `SeverityNumber` range table (1-4 TRACE…TRACE4, 5-8 DEBUG…DEBUG4, 9-12 INFO…INFO4, 13-16 WARN…WARN4, 17-20 ERROR…ERROR4, 21-24 FATAL…FATAL4) with exact per-value short names. | Stable (`data-model.md:262-269,338-363`) | ✅ | **Fixed by #2449** (`fix!`, merged 2026-10-09; previously ❌). `logs_api/lib/opentelemetry/logs/severity_number.rb:15-18` now has `DEBUG = 5`, `DEBUG2 = 6`, `DEBUG3 = 7`, `DEBUG4 = 8`, matching `data-model.md:345-346`; every other constant was already correct. Breaking change for callers who relied on the swapped values. |
| DM-5 | Errors/exceptions included in `Attributes` MUST follow the OTel exception-attribute semantic conventions. | Stable (`data-model.md:442-443`) | N/A | Previously ❌ — overstated. The MUST applies to whoever populates `Attributes` with error data; with no exception bridging (SDK-21, N/A) the SDK never writes such attributes, so there is nothing for it to get wrong. Becomes relevant when #2349 lands. |
| DM-6 | `EventName` SHOULD uniquely identify the event structure (attributes and body). | Stable (`data-model.md:445-450`) | ✅ | `event_name` is accepted, stored, and exported as a free-form string with no SDK-side validation or mutation (`log_record.rb:71,85`; `log_record_data.rb:17`; `logs_exporter.rb:313`) — correctly left to the caller to name meaningfully, consistent with this being descriptive guidance rather than an enforceable rule. |

---

## OTLP Logs Exporter

Sourced from the shared `specification/protocol/exporter.md` (Logs has no dedicated
`sdk_exporters/otlp.md`), cross-checked against `exporter/otlp-logs/lib/opentelemetry/exporter/otlp/logs/logs_exporter.rb`.

Since #2434 (merged 2026-10-07), request encoding lives in `exporter/otlp-common/lib/opentelemetry/exporter/otlp/common.rb`
(`as_encoded_elsr`/`as_otlp_log_record`/`as_otlp_any_value`) and endpoint resolution in
`exporter/otlp-common/.../common/utilities.rb` (`build_uri`); `logs_exporter.rb` line numbers below that refer to
encoding or endpoint code are stale. Open refactor PRs #2432 (open) and #2447 (draft) centralize the HTTP client/send
path and #2238 (open) adds OTLP/JSON; none of them changes redirect, root-path, flags, or schema_url behavior, so
they are **not** treated as fixes for any row.

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| OTLP-1 | Endpoint (HTTP): per-signal env var override takes precedence and is used as-is; otherwise the generic `OTEL_EXPORTER_OTLP_ENDPOINT` is used as a base with `v1/logs` appended; default `http://localhost:4318`. | Stable (`exporter.md:16-29,104-121`) | ✅ | `logs_exporter.rb:53` (`OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` → `OTEL_EXPORTER_OTLP_ENDPOINT` → default `http://localhost:4318/v1/logs`); `:64-69` builds `URI.join(endpoint, 'v1/logs')` specifically when the resolved value came from the *generic* endpoint var, and uses a per-signal endpoint URL as-is otherwise — matches `exporter.md`'s Example 1/3 construction rules. |
| OTLP-2 | If a per-signal endpoint URL has no path component, the root path `/` MUST be used (not silently dropped). | Stable (`exporter.md:110-111`, Example 2) | ⚠️ | **Untracked** — proposed in `new-logs-issues.json`. (Still true on `upstream/main`: `build_uri` returns `URI(endpoint)` unmodified.) For a per-signal endpoint (e.g. `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://collector:4318`), `:68` does `URI(endpoint)` as-is; `URI('http://collector:4318').path` is `''` (empty string), not `'/'`, and that empty string becomes `@path` (`:73`), then `Net::HTTP::Post.new(@path)` (`:145`) — the root-path normalization the spec requires isn't performed anywhere in this constructor. |
| OTLP-3 | Certificate File / Client key file / Client certificate file, each with a per-signal-then-generic env var fallback. | Stable (`exporter.md:41-54`) | ✅ | `logs_exporter.rb:54-56` (`_LOGS_CERTIFICATE`/`_LOGS_CLIENT_CERTIFICATE`/`_LOGS_CLIENT_KEY` → generic), applied via `http.ca_file`/`http.cert`/`http.key` (`:124-126`). |
| OTLP-4 | Headers, comma-separated `k=v` pairs (W3C-Baggage-like format), per-signal-then-generic env var. | Stable (`exporter.md:56-59,186-188`) | ✅ | `logs_exporter.rb:58` (`OTEL_EXPORTER_OTLP_LOGS_HEADERS` → `OTEL_EXPORTER_OTLP_HEADERS`); `parse_headers` (`:362-380`) splits on `,` then `=`. |
| OTLP-5 | Compression: supported values `gzip`/`none`, per-signal-then-generic env var. | Stable (`exporter.md:61-64,99-102`) | ✅ | `logs_exporter.rb:59,62` (env var + `%w[gzip none]` validation), applied at `:146-151` (`Zlib.gzip` + `Content-Encoding: gzip`). |
| OTLP-6 | Timeout, default 10s, per-signal-then-generic env var. | Stable (`exporter.md:66-69`) | ✅ | `logs_exporter.rb:60` (`OTEL_EXPORTER_OTLP_LOGS_TIMEOUT` → `OTEL_EXPORTER_OTLP_TIMEOUT`, default `10`). |
| OTLP-7 | Max Request Size (default 64 MiB) / Max Response Size (default 4 MiB) SHOULD be enforced. | Stable (`exporter.md:71-78`) | ❌ | **Tracked: #2436** (open; OTLP/HTTP exporters generally — not in milestone 12, no PR). No request- or response-size check anywhere in `logs_exporter.rb`. Consistent with the org-wide `spec-compliance-matrix.md`, which leaves the "Enforces request/response size limit" cells blank for every language, Ruby included — an ecosystem-wide gap, not a logs-specific regression. |
| OTLP-8 | Protocol option: SHOULD support both `grpc` and `http/protobuf`, MUST support at least one; default `http/protobuf`. | Stable (`exporter.md:79-83,169-184`) | ⚠️ | Ruby's `exporter/otlp-logs` implements only HTTP/protobuf — satisfies "MUST support at least one" ✅, and `logs_sdk/.../configurator_patch.rb:46-58` checks `OTEL_EXPORTER_OTLP_LOGS_PROTOCOL`/`OTEL_EXPORTER_OTLP_PROTOCOL`, warning and disabling export for anything other than `'http/protobuf'`. No gRPC transport exists at all, so the "SHOULD support both" bar isn't met — matches the org matrix's blank Ruby cell for "OTLP/gRPC exporter". |
| OTLP-9 | Retry: transient errors MUST be handled with exponential backoff with jitter. | Stable (`exporter.md:190-192`) | ✅ | `backoff?` (`logs_exporter.rb:253-272`) uses `rand(2**retry_count)` jitter, capped at `RETRY_COUNT = 5` (`:33-34,254`), and honors a numeric-or-HTTP-date `Retry-After` header when present (`:257-266`). |
| OTLP-10 | Transient errors = retryable HTTP status codes plus connection-level failure scenarios. | Stable (`exporter.md:194-209`) | ✅ | Retries on `503`/`429` (honoring `Retry-After`, `:176-180`), `408`/`504`/`502` (`:181-185`), and `Net::OpenTimeout`/`ReadTimeout`/`OpenSSL::SSL::SSLError`/`SocketError`/`SystemCallError`/`EOFError`/`Zlib::DataError` (`:201-224`). Non-retryable `404`/`400`/other 4xx/5xx correctly fail fast without retry (`:186-191`). |
| OTLP-11 | HTTP redirects SHOULD be followed (general OTLP/HTTP connection-handling expectation referenced at `exporter.md:206-209`). | Stable | ❌ | **Untracked for Logs** (Metrics equivalent: #2371, in the Metrics milestone) — proposed in `new-logs-issues.json`. The redirect expectation comes from the OTLP/HTTP protocol spec that `exporter.md:206-209` links to, which is not in the local spec checkout and was not re-read in this pass. `Net::HTTPRedirection` responses close the connection and call `handle_redirect(response['location'])` (`logs_exporter.rb:192-195`), but `handle_redirect` (`:237-239`) is a literal no-op (just a `# TODO` comment) — the subsequent `redo` (`:195`) re-sends the identical request to the **original** `@path`/`@http`, never the `Location` from the response. Same class of gap the Metrics OTLP exporter has (documented as OTLP-10 in `SPEC_COMPLIANCE_METRICS.md`). |
| OTLP-12 | User-Agent SHOULD identify the exporter, language, and version, formatted per RFC 7231; a caller-supplied product identifier SHOULD be prepended ahead of the exporter's own string. | Stable (`exporter.md:211-225`) | ✅ | `DEFAULT_USER_AGENT = "OTel-OTLP-Exporter-Ruby/#{VERSION} Ruby/#{RUBY_VERSION} (...)"` (`logs_exporter.rb:39`); `prepare_headers` (`:349-360`) builds `"#{existing_user_agent} #{DEFAULT_USER_AGENT}".strip` — matches the spec's own worked example ordering (`MyDistribution/x.y.z OTel-OTLP-Exporter-Python/1.2.3`, `exporter.md:224`). |
| OTLP-13 | `ExportLogsServiceResponse.partial_success` (`rejected_log_records`, `error_message`) SHOULD be handled/logged on an otherwise-2xx response. | (general OTLP protocol behavior, cf. Metrics doc's equivalent finding) | ✅ | **Fixed by #2396** (merged 2026-09-29, closed #2355; previously ❌). On `Net::HTTPSuccess` the exporter now calls `log_partial_success`, which decodes `ExportLogsServiceResponse` and reports `rejected_log_records`/`error_message` via `OpenTelemetry.handle_error`, still returning `SUCCESS`. Minor residual: it returns early when `rejected_log_records <= 0`, so a response with 0 rejected but a non-empty `error_message` (which the OTLP protocol says clients should treat as a warning) is not logged — not re-checked against the protocol text, which is not in the local spec checkout. |
| OTLP-14 | Resource/Scope `schema_url` SHOULD be carried through to `ResourceLogs`/`ScopeLogs`. | (data-model.md:404-425 field-carrying expectation) | ❌ | **Tracked indirectly** by #2380/#2381/#2382 (not in milestone 12; no logs PR — see API-5). `as_elsr` in `exporter/otlp-common/.../common.rb` builds `Resource.new`/`InstrumentationScope.new` with only `attributes` / `name`+`version` — it sets neither `schema_url` nor scope `attributes` (the latter is a new observation: the `attributes` member added to `InstrumentationScope` in #2094 is never encoded). Root cause is upstream of this exporter: neither `OpenTelemetry::SDK::Resources::Resource` nor `OpenTelemetry::SDK::InstrumentationScope` (in the main `sdk` gem) carry a `schema_url` attribute at all — the same systemic gap the org-wide `spec-compliance-matrix.md` already shows blank for Ruby's Tracer/Meter `schema_url` support (API-5 above). |
| OTLP-15 | `TraceFlags` encoding onto the wire `flags` field. | (data-model.md `TraceFlags` field semantics) | ⚠️ | **Tracked: #2354** (milestone 12; no linked PR; issue marked stale 2026-10-11). `as_otlp_log_record` reads `log_record_data.trace_flags.instance_variable_get(:@flags)` (now `exporter/otlp-common/.../common.rb:183`) — this only works when `trace_flags` is an `OpenTelemetry::Trace::TraceFlags` object (the case when it's auto-derived from the current span context, `logs_sdk/.../logger.rb:78,89`). If a caller instead passes a raw `Integer` explicitly (which is what the SDK's own API docs describe the field as — `log_record_data.rb:20` says "optional Integer (8-bit byte of bit flags)"), `Integer#instance_variable_get(:@flags)` silently returns `nil` rather than the intended bit value, with no error raised. |

---

## Stdout Exporter (`sdk_exporters/stdout.md`)

| § | Requirement (paraphrased) | Stability | Status | Notes / Links |
| --- | --- | --- | --- | --- |
| STDOUT-1 | Output format is unspecified and can vary; documentation SHOULD warn users it's for debugging/learning only, not production. | Stable (`stdout.md:12-18`) | ✅ | **Fixed by #2450** (merged 2026-10-10; previously ⚠️). `ConsoleLogRecordExporter#export` pretty-prints via `pp` (unspecified format), and the class doc now states: "intended for debugging and learning purposes. It is not recommended for production use. The output format is not standardized and can change at any time." |
| STDOUT-2 | SDK authors MAY choose any idiomatic name (ConsoleExporter, StdoutExporter, etc.). | Stable, MAY (`stdout.md:25-27`) | ✅ | Named `ConsoleLogRecordExporter` — an accepted idiomatic choice. |
| STDOUT-3 | If the language auto-configures a `LogRecordProcessor` to pair with this exporter (e.g. via `OTEL_LOGS_EXPORTER`), it SHOULD default to pairing with the **Simple** processor. | Stable (`stdout.md:29-34`) | ✅ | `logs_sdk/lib/opentelemetry/sdk/logs/configurator_patch.rb:44` — `when 'console' then Logs::Export::SimpleLogRecordProcessor.new(Logs::Export::ConsoleLogRecordExporter.new)` — correctly Simple, not Batch. |

---

## Milestone tracker: Logs: Stability Prep

[Milestone 12](https://github.com/open-telemetry/opentelemetry-ruby/milestone/12) — 1 closed, 9 open as of 2026-10-12.
Linked PRs were taken from each issue's GraphQL `closedByPullRequestsReferences` and timeline cross-references (not
title search). Only two issues have any linked PR.

| Issue | Spec rows | Linked PR | PR status | Resolves the issue? | Spec-row status |
| --- | --- | --- | --- | --- | --- |
| #2355 Handle `partial_success` (closed 2026-09-29) | OTLP-13 | #2396 | **Merged** 2026-09-29, approved | **Fully** (decode + report rejected records; see OTLP-13 caveat) | ✅ |
| #2351 Discard messages at most once per `LogRecord` | SDK-31 | #2394 | **Open**, not draft, **approved** (2), but `CONFLICTING` and CI red on otlp-logs jobs (2026-09-29 run) | **Fully for #2351's stated scope**, once rebased and merged (see below) | 🚧 in progress — not compliant until merged |
| #2346 `attributes` on `LoggerProvider#logger` | API-6, NOOP-2 | none | — | — | ❌ |
| #2347 Ergonomic/event API | API-15 | none | — | — | ❌ (MAY, Development) |
| #2348 `Logger#enabled?` | API-8, API-11, NOOP-4, SDK-23, SDK-24, SDK-35 | none | — | — | ❌ |
| #2349 `exception:` param | API-10, SDK-21, DM-5 | none | — | — | ❌ API-10 (MAY); SDK-21/DM-5 N/A until it exists |
| #2350 Restrict `Logger.new` | SDK-3 | none | — | — | ⚠️ (SHOULD) |
| #2352 Event→span-event bridge | SDK-41 | none | — | — | ❌ (Development) |
| #2353 Console/OTLP exporter concurrency | SDK-42, SDK-50 | none | — | — | ⚠️ |
| #2354 `AnyValue`/`TraceFlags` encoding | DM-1, OTLP-15 | none | — | — | DM-1 ✅ (issue half-inaccurate); OTLP-15 ⚠️ |

**Analysis of PR #2394 against #2351.** The diff replaces the two per-path behaviors with one
`OpenTelemetry.handle_error` call (`"Discarded N log record attributes due to limits or invalid values"`) emitted at the end of
`trim_attributes`, counting both count-limit truncations and validation drops, and fixes `validate_attributes` so invalid
attributes are really removed. That satisfies `sdk.md:354-357` ("at most once per `LogRecord`") for a record built through
`LogRecord.new`. Caveats to resolve before treating it as a complete fix: (a) `attributes=` re-runs `trim_attributes`, so a
caller that re-assigns attributes can produce a second message for the same `LogRecord`; (b) it must be rebased onto the
`@dropped_attributes_count` bookkeeping now on `main` — the PR's `truncate_attributes` as written would drop that counter
on a naive conflict resolution; (c) validation drops still do not feed `dropped_attributes_count`; (d) the otlp-logs CI
failure should be confirmed unrelated.

**Issues that can be closed.** None can be closed on the strength of current code. #2355 is already closed. #2351 closes
automatically (`Fixes #2351`) if #2394 merges. All of #2346–#2350, #2352–#2354 describe gaps that still exist.

**Fixes that landed without a milestone issue** (no issue to close; noted for the record): #2452 (SDK-11), #2449 (DM-4),
#2450 (STDOUT-1), #2451 (SDK-20 comment only), #2375/#2376 (API `LoggerProvider#logger` now matches the SDK signature and
forwards `on_emit` args — supports API-2/API-3/API-4), #2415 (API-1 trade-off), #2434 (encoder moved to `otlp-common`).

## Issue accuracy review

- **#2354 is partly inaccurate.** It says `body: nil` "is indistinguishable on the wire from an explicitly-empty `AnyValue`"
  and treats that as silent data loss. Per `common/README.md:52-53,61-63`, `nil` *is* the Ruby empty value, an empty
  `AnyValue` is how it is represented, and it MUST be passed on — which it is. The `TraceFlags` half is valid (an
  Integer passed as `trace_flags:` encodes as `nil`/0, contradicting the SDK's own docs). Its file/line references are
  stale (moved to `exporter/otlp-common` by #2434). Suggest narrowing it to the `TraceFlags` fix plus an explicit decision on
  non-`AnyValue` Ruby types (`Symbol`, `Time`, …), and re-titling.
- **#2349's "Spec requirement" overstates the obligation.** The API *MAY* accept an exception (`api.md:127-129`); the SDK
  MUST bridge only *if* one is provided (`sdk.md:233-237`). That makes it a valid enhancement, not a conformance defect;
  SDK-21 and DM-5 were over-marked ❌ in the first version of this document and are now N/A until the parameter exists.
- **#2351 / SDK-31 diagnosis was wrong in this document** (and the issue inherits it): the validity path does *not* log once
  per invalid attribute — `return false` inside `keep_if` aborts on the first invalid attribute (verified with a Ruby
  snippet), so it logs at most once *and* leaves the invalid attribute in place. Also, the spec's "discarded due to such a
  limit" refers to attribute limits; reporting *invalid* attributes in the same message is reasonable but goes beyond the
  letter of `sdk.md:354-357`. #2394 handles the real defects.
- **#2347 and #2352 are Development/MAY-level** (`api.md:181-190`; `sdk.md:561-600` is `[Development]`) — valid
  enhancements, but not Stable conformance gaps. Fine to keep in the milestone; labels should not read `spec:stable`.
- **#2346 is accurate but incomplete:** `schema_url` (API-5), the other half of the same Get-a-Logger requirement, is
  tracked only outside the milestone (#2380 family, stale), and the scope-attribute encoding gap (OTLP-14) is not mentioned.
- **#2348, #2350, #2353 are accurate.** (#2350 is a SHOULD and the issue already says to weigh the trade-off; #2353's
  "document concurrency" half is a MUST.)

---

## Summary of gaps

### Stable — missing entirely

- **`Logger#enabled?`** (API-8, NOOP-4, SDK-23): no `Enabled` method exists anywhere in `logs_api` or `logs_sdk` — a Stable SHOULD/MUST with real performance implications (its whole purpose is letting callers skip expensive `LogRecord` construction), and the no-op layer can't even satisfy noop.md's "MUST always return false" since the method doesn't exist to call.
- **`schema_url` / `attributes` on Get-a-Logger** (API-5, API-6): silently unsupported; `schema_url` is a systemic gap across the whole Ruby SDK (Tracer/Meter/Logger all lack it), not logs-specific.
- **Exception parameter on Emit-a-LogRecord** (API-10, optional MAY; SDK-21/DM-5 N/A until it exists): no way to pass an exception and have the SDK derive semconv attributes from it.
- **OTLP redirect following** (OTLP-11): `handle_redirect` is a literal no-op; the exporter retries against the original URI, never the `Location` header — same defect class as the Metrics OTLP exporter (#2371).
- **OTLP `schema_url` and scope `attributes` on Resource/Scope** (OTLP-14): never encoded; `schema_url` is also missing from `Resource`/`InstrumentationScope`.

Resolved since the 2026-08-19 version of this document: SDK-11 (#2452), DM-4 (#2449), OTLP-13 (#2396), STDOUT-1 (#2450);
DM-1, SDK-21, and DM-5 were re-assessed (see "Issue accuracy review"). In progress: SDK-31 (#2394, open/approved/conflicting).
- **Event-to-span-event bridge processor** (SDK-41, Development): entirely absent.
- **`LoggerConfigurator`/`LoggerConfig`** (SDK-7, SDK-10, SDK-15 through SDK-19, SDK-22, SDK-24, Development): no `enabled`/`minimum_severity`/`trace_based` filtering exists anywhere.
- **SDK self-observability** (SDK-51, Development).

### Stable — partial / behavioral deviations

- **Discard-logging for attribute limits** (SDK-31) 🚧 #2394: the count-limit path never logs a discard message; the validity path aborts on the first invalid attribute (logging once, but neither dropping it nor checking the rest).
- **`ObservedTimestamp` default disagreement between layers** (SDK-20): `Logger#on_emit`'s keyword default is `Time.now` (spec-correct), but `LogRecord#initialize` itself falls back to a caller-supplied `timestamp` before `Time.now` — the two entry points don't agree on which spec reading to satisfy.
- **`BatchLogRecordProcessor` holds a live `LogRecord` reference, not a clone** (SDK-29, SDK-34): the spec makes concurrent-safety and cloning optional, but Ruby offers neither a deep-clone operation nor any mitigation for the exact mutation race the spec calls out by name.
- **`SimpleLogRecordProcessor#shutdown`/`#force_flush` return `nil` instead of a status constant when already stopped** (SDK-36): a minor status-reporting deviation.
- **`ConsoleLogRecordExporter` and the OTLP exporter aren't internally concurrency-safe for `ForceFlush`/`Shutdown`** (SDK-42, SDK-50): no mutex protects `@stopped`/`@shutdown`, relying entirely on callers not to race — `InMemoryLogRecordExporter` is the only one that actually guards this.
- **OTLP root-path normalization missing for bare per-signal endpoints** (OTLP-2): `URI('http://host:port').path` is `''`, not `/`, and nothing corrects it before building the HTTP request.
- **OTLP `TraceFlags` encoding is type-fragile** (OTLP-15, #2354): works for the auto-derived `TraceFlags` object case, silently produces `nil` for a caller-supplied raw `Integer`, which is what the SDK's own documentation says the field's type should be.
- **No OTLP gRPC transport** (OTLP-8): HTTP/protobuf-only satisfies the "at least one" MUST, but not the "SHOULD support both" bar.
- **Request/response size limits unenforced** (OTLP-7): matches every other language in the org-wide matrix, so not a Ruby-specific regression, but still an open Stable gap.
- **`Logger` instances aren't language-enforced to be `LoggerProvider`-only** (SDK-3): `Logger.new` is a public constructor, restricted only by a docstring comment.

### Development — missing entirely (upstream still in flux; lower urgency)

- **`LoggerConfigurator`/`LoggerConfig`** (SDK-7 through SDK-19, SDK-22, SDK-24) — covered above; repeated here because it's the single largest block of Development-status gaps in this signal.
- **Event-to-span-event bridge** (SDK-41).
- **SDK self-observability** (SDK-51).
- **Ergonomic API** (API-15) — no event-semantics-friendly convenience layer over the base Logs API.

---
