# Contributing

We welcome your contributions to this project!

Please read the [OpenTelemetry Contributor Guide][otel-contributor-guide]
for general information on how to contribute including signing the Contributor License Agreement, the Code of Conduct, and Community Expectations.

## Before you begin

### Specifications / Guidelines

As with other OpenTelemetry clients, opentelemetry-ruby follows the
[opentelemetry-specification][otel-specification] and the
[library guidelines][otel-lib-guidelines].

### Focus on Capabilities, Not Structure Compliance

OpenTelemetry is an evolving specification, one where the desires and
use cases are clear, but the method to satisfy those uses cases are not.

As such, Contributions should provide functionality and behavior that
conforms to the specification, but the interface and structure are flexible.

It is preferable to have contributions follow the idioms of the language
rather than conform to specific API names or argument patterns in the spec.

For a deeper discussion, see: https://github.com/open-telemetry/opentelemetry-specification/issues/165

## Getting started

Everyone is welcome to contribute code via GitHub Pull Requests (PRs).

### Fork the repo

Fork the project on GitHub by clicking the `Fork` button at the top of the
repository and clone your fork locally:

```sh
git clone git@github.com:YOUR_GITHUB_NAME/opentelemetry-ruby.git
```

or
```sh
git clone https://github.com/YOUR_GITHUB_NAME/opentelemetry-ruby.git
```

It can be helpful to add the `open-telemetry/opentelemetry-ruby` repo as a
remote so you can track changes (we're adding as `upstream` here):

```sh
git remote add upstream git@github.com:open-telemetry/opentelemetry-ruby.git
```

or

```sh
git remote add upstream https://github.com/open-telemetry/opentelemetry-ruby.git
```

For more detailed information on this workflow read the
[GitHub Workflow][otel-github-workflow].

### Run the tests

_Setting up a running Ruby environment is outside the scope of this document._

This repository contains two Ruby gems:

  * `opentelemetry-api`: located at `api/opentelemetry-api.gemspec`
  * `opentelemetry-sdk`: located at `sdk/opentelemetry-sdk.gemspec`

Each of these gems has its configuration and tests.

For example, to test the `api` you would:

  1. Change directory to `api`
  2. Run the tests with ```rake test```

### Make your modifications

Always work in a branch from your fork:

```sh
git checkout -b my-feature-branch
```

### Create a Pull Request

You'll need to create a Pull Request once you've finished your work.
The [Kubernetes GitHub Workflow][kube-github-workflow-pr] document has
a significant section on PRs.

Open the PR against the `open-telemetry/opentelemetry-ruby` repository.

Please put `[WIP]` in the title, or create it as a [`Draft`][github-draft] PR
if the PR is not ready for review.

#### Sign the Contributor License Agreement (CLA)

All PRs are automatically checked for a signed CLA. Your first PR fails this
check if you haven't signed the [CNCF CLA][cncf-cla].

The failed check displays a link to `details` which walks you through the
process. Don't worry it's painless!

### Review and feedback

PRs require a review from one or more of the [code owners](CODEOWNERS) before
merge. You'll probably get some feedback from these fine folks which helps to
make the project that much better. Respond to the feedback and work with your
reviewer(s) to resolve any issues.


[cncf-cla]: https://identity.linuxfoundation.org/projects/cncf
[github-draft]: https://github.blog/2019-02-14-introducing-draft-pull-requests/
[kube-github-workflow-pr]: https://github.com/kubernetes/community/blob/master/contributors/guide/github-workflow.md#7-create-a-pull-request
[otel-contributor-guide]: https://github.com/open-telemetry/community/blob/master/CONTRIBUTING.md
[otel-github-workflow]: https://github.com/open-telemetry/community/blob/master/CONTRIBUTING.md#github-workflow
[otel-lib-guidelines]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/library-guidelines.md
[otel-specification]: https://github.com/open-telemetry/opentelemetry-specification
