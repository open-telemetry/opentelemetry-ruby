Examples for OpenTelemetry GRPC auto-instrumentation. Adapted from the [gRPC tutorial][grpc-tutorial].

1. Launch the server: `./route_guide_server.rb data/route_guide_db.json`
1. In a separate terminal, launch the client: `./route_guide_client.rb data/route_guide_db.json`

Both the client and the server should print traces to your terminals.

[grpc-tutorial]: https://grpc.io/docs/languages/ruby/basics
