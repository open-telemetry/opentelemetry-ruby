This document is focused on the general design patterns being used within this project and their relationship to patterns used in other language's opentelemtry implementations.

## Language Idioms
Each reference implementation is following language idioms that make sense, for instance in ruby `isRecording` [defined here in the spec](https://github.com/open-telemetry/opentelemetry-specification/blob/ccbf36374730488548703a65af40d9051d7ab944/specification/api-tracing.md#isrecording) is implemented as `recording?` instead which matches the ruby convention to end methods that return bool with a question mark.

Although this does not match the definition in the language agnostic spec, the goal of the spec is to make the developer experience between languages as seemless as possible, not to have everything match perfectly across languages.

## Project Layout
The spec offers a [recommended project layout](https://github.com/open-telemetry/opentelemetry-specification/blob/8da573bf85ed1a7ff0fbf0998ed45b4738416aa8/specification/library-layout.md)

The key ideas are
1. Seperate the api and sdk
2. Modularize code using the concerns defined in the spec e.g. `context` and `metrics`

This implementation follows both of those conventions. In addition it packages the code for each as seperate gems. There is a bit of additional boilerplate under the top level folders `api` and `sdk` folders because of how gems are packaged, so you have to traverse down to `api/lib/opentelemetry` to see the concerns defined by the spec.

## Prototyping Related Tools
Some additional top level directories currently exist in this repo (namely exporters and adapters). Eventually their contents will probably be split out into stand alone projects.

Other language implementations (e.g. golang) also have exporters defined within their project (as well as tools like a bridge for OpenTracing).  How much, if any, of these related tools should be in the core sdk gem is up for debate.
