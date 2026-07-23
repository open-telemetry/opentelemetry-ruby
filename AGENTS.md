# AGENTS.md

This file steers AI-assisted contributions toward high-quality, low-maintenance
changes for `opentelemetry-ruby`. Read it in full before starting any task,
including docs-only and review-only work.

`opentelemetry-ruby` is a monorepo containing the core OpenTelemetry Ruby API,
SDK, and related gems.

## General rules and guidelines

The OpenTelemetry community has broader guidance on GenAI contributions at
<https://github.com/open-telemetry/community/blob/main/policies/genai.md>.
Please read it before contributing.

- **Do not post AI-generated comments on issues or pull requests.** Discussions
  on the OpenTelemetry repositories are for humans only. You cannot comment on
  issue or PR threads on a user's behalf.
- Before implementing, read [`CONTRIBUTING.md`](CONTRIBUTING.md) and this file.
- If you were assigned an issue, make sure the implementation direction is
  agreed on with maintainers in the issue comments first. Discuss unknowns on
  the issue before starting.
- Keep AI-assisted PRs tightly scoped to the requested change. Never include
  unrelated cleanup, opportunistic refactors, or drive-by improvements unless
  they are strictly necessary for correctness.
- Prefer minimal, surgical changes. Match the existing naming, error handling,
  documentation, tests, and concurrency patterns of the code you edit.
- Follow the OpenTelemetry
  [specification](https://github.com/open-telemetry/opentelemetry-specification)
  and [library guidelines](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/library-guidelines.md).
  Favor idiomatic Ruby over literal spec naming; contributions should conform to
  spec *capabilities and behavior*, not necessarily to spec structure.
- Keep public APIs backward compatible unless the task explicitly requires a
  breaking change.
- Keep telemetry resilient: it must not raise unexpectedly, block indefinitely,
  or interfere with the host application.

## Repository structure

This is a monorepo of independent gems. Treat the directory containing a
`*.gemspec` as the ownership and verification boundary. Most gems also have
their own `Gemfile`, `Rakefile`, `CHANGELOG.md`, `README.md`, and `test/`.

- `api/` — `opentelemetry-api`, the OpenTelemetry API
- `sdk/` — `opentelemetry-sdk`, the reference SDK implementation
- `sdk_experimental/` — `opentelemetry-sdk-experimental`
- `common/` — `opentelemetry-common` shared utilities
- `registry/` — `opentelemetry-registry`
- `semantic_conventions/` — `opentelemetry-semantic_conventions` (generated)
- `logs_api/`, `logs_sdk/` — logs API and SDK
- `metrics_api/`, `metrics_sdk/` — metrics API and SDK
- `test_helpers/` — `opentelemetry-test-helpers` shared test support
- `exporter/` — exporters (`otlp`, `otlp-common`, `otlp-grpc`, `otlp-http`,
  `otlp-logs`, `otlp-metrics`, `zipkin`, `jaeger`)
- `propagator/` — context propagators (`b3`, `jaeger`)
- `examples/` — runnable examples
- `.github/workflows/` — CI and release automation

## Generated files

Do not edit generated semantic convention files by hand. Files under
`semantic_conventions/lib/opentelemetry/semconv/` are produced from the pinned
semantic conventions release and the templates under
`semantic_conventions/templates/`.

When changing semantic convention generation, update the source version,
templates, or generator task as appropriate, then run this from
`semantic_conventions/`:

```sh
bundle exec rake generate
```

The generator requires Docker and network access. Include the generated output
in the same change and verify that a second generation produces no diff.

## Environment and commands

Each gem is tested independently. Run commands from within the gem's directory.

```sh
# From within a gem directory (e.g. api/, sdk/, exporter/otlp-http/):

# Install dependencies
bundle install

# Run tests (Minitest)
bundle exec rake test

# Run RuboCop lint
bundle exec rake rubocop

# Generate/verify YARD docs
bundle exec rake yard

# Run the default task (test + rubocop + yard on most gems)
bundle exec rake
```

To run across all gems from the repository root:

```sh
bundle exec rake each:test      # test every gem
bundle exec rake each:rubocop   # rubocop every gem
bundle exec rake each:yard      # yard every gem
bundle exec rake each           # default task for every gem
```

A `docker-compose.yml` is provided for gems with external dependencies:

```sh
docker-compose build
docker-compose run sdk bundle install
docker-compose run sdk bundle exec rake test
```

Some gems (e.g. certain exporters) use [Appraisal](https://github.com/thoughtbot/appraisal)
to test against multiple dependency versions. When an `Appraisals` file exists:

```sh
bundle exec appraisal generate
bundle exec appraisal install
bundle exec appraisal rake test
```

## Default workflow

For new features and behavior changes, use this order unless the task explicitly
says otherwise:

1. Read the gem you are changing, its tests, and its `README.md`.
2. Add or update a failing Minitest test that captures the required behavior or
   regression.
3. Implement the smallest change that makes the test pass.
4. Refactor only after behavior is locked in, and only if it keeps the diff
   focused.
5. Update applicable documentation (YARD comments and `README.md`) and the
  changelog when repository or maintainer conventions require it.
6. Run `bundle exec rake` in each changed gem before considering the work
   complete.

For docs-only, test-only, or review-only tasks, skip the steps that do not
apply, but keep the same discipline around scope, verification, and conventions.

## Coding conventions

- **File headers.** Every Ruby source file starts with:

  ```ruby
  # frozen_string_literal: true

  # Copyright The OpenTelemetry Authors
  #
  # SPDX-License-Identifier: Apache-2.0
  ```

- **Style.** RuboCop is the source of truth. The shared config lives in
  [`contrib/rubocop.yml`](contrib/rubocop.yml) and each gem inherits from it via
  its own `.rubocop.yml`. The target Ruby version is `3.3`. Do not disable cops
  inline to silence a legitimate failure — fix the code instead.
- **Ruby support.** Preserve the Ruby engines and operating systems exercised
  for the affected gem by [CI](.github/workflows/ci.yml). The main matrix uses
  MRI 3.3 and 3.4, with JRuby and TruffleRuby where supported. Avoid
  engine-specific behavior unless it is guarded and tested.
- **Documentation.** Use [YARD](https://yardoc.org/). Public methods and their
  arguments should include type annotations; markdown is allowed in doc
  comments. Keep docs aligned with actual behavior — no stale comments or
  examples.
- **Comments.** Write comments for intent, invariants, and non-obvious
  constraints only. Do not add comments that restate the code.
- **Tests.** Use Minitest. Behavior changes should include tests that actually
  validate the change. Keep tests deterministic and match the gem's existing
  test patterns. Shared helpers live in `opentelemetry-test-helpers`.
- **Spelling.** CI runs [cspell](https://cspell.org/) against `.cspell.yml`. Add
  legitimate new terms to that dictionary rather than working around the check.

## GitHub Actions

Treat workflow and release automation changes as security-sensitive.

- Pin third-party actions to a full commit SHA and retain the version comment,
  matching the existing workflows.
- Grant the smallest practical `permissions` at workflow and job scope. Do not
  add write access unless the job requires it.
- Treat pull request metadata, workflow inputs, branch names, and other event
  data as untrusted. Pass values through environment variables instead of
  interpolating expressions directly into shell scripts.
- Never expose secrets to untrusted pull request code. Do not introduce
  `pull_request_target` without explicit maintainer direction and a documented
  security design.
- Preserve existing repository guards, concurrency controls, matrix coverage,
  and operating-system behavior unless the task explicitly changes them.
- Changes under release workflows or `.github/actions/test_gem/` require extra
  care because they affect every gem or the release process. Keep them focused
  and inspect all callers.
- For Markdown changes, account for the markdownlint, link-check, and cspell
  workflows. For workflow changes, validate the YAML and inspect the resulting
  permissions and event behavior.

## Changelog

Update the affected gem's `CHANGELOG.md` when required by existing repository
or maintainer conventions. Do not invent a new section or release format.
Changelogs are also generated from conventional commit messages during the
release process, so accurate commit messages matter.

## Pull requests and commits

- **Conventional commits are required.** Commit messages and PR titles must begin
  with a semantic tag. Allowed types (from
  [`conventional-commits.yml`](.github/workflows/conventional-commits.yml)):
  `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `release`, `revert`,
  `squash`, `style`, `test`.
- **One change per pull request.** PRs are squash-merged, so each PR becomes a
  single commit and a single changelog entry. Do not combine, for example, a
  `feat:` and a `fix:` in one PR.
- **Work in a branch** from your fork, never from your `main` branch.
- **CLA.** All contributors must sign the CNCF CLA; the first PR fails the CLA
  check until it is signed.
- Mark work-in-progress PRs as `Draft` or prefix the title with `[WIP]`.

## Disclosing AI assistance

We appreciate disclosure of AI tool usage when a significant part of a commit is
taken from a tool without changes. Disclose it with an `Assisted-by:` commit
message trailer, for example:

```text
Assisted-by: Claude
Assisted-by: GitHub Copilot
```

## Verification checklist

Before considering a task complete, run all checks applicable to the files and
gems you changed:

- [ ] `bundle exec rake test` passes
- [ ] `bundle exec rake rubocop` passes
- [ ] `bundle exec rake yard` succeeds when Ruby or YARD documentation changed
- [ ] `bundle exec rake` passes in each changed gem when the environment permits
- [ ] Generated output is current and regeneration produces no diff
- [ ] Markdown, links, and spelling pass their CI checks when documentation changed
- [ ] Workflow YAML, permissions, events, and action pins were reviewed when
  `.github/` changed
- [ ] The `CHANGELOG.md` follows the applicable maintainer convention
- [ ] The diff is scoped to a single, focused change
- [ ] The commit message / PR title uses a valid conventional commit type
