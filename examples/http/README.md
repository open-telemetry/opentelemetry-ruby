# OpenTelemetry Ruby Example

## HTTP

This is a simple example that demonstrates tracing an HTTP request from client to server. The example shows several aspects of tracing, such as:

* Using the `TracerProvider`
* Span Attributes
* Using the console exporter

### Running the example

The example uses Docker Compose to make it a bit easier to get things up and running.

1. Follow the `Developer Setup` instructions in [the main README](../../README.md)
1. Run the server using the `ex-http` compose service
    * `docker-compose run ex-http`
1. After a few seconds, an interactive shell should appear
1. Run the client
    * `./client.rb`
1. You should see console exporter output for both the client and server sessions
