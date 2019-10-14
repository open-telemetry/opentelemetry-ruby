# OpenTelemetry Ruby Example

## HTTP (Grape)

This example demonstrates tracing an HTTP server response. The example shows several aspects of tracing, such as:

* Using the `TracerFactory`
* Span Events
* Span Attributes
* Creating a simple exporter (`Examples::Exporters::Console`)

### Running the example

The example uses Docker Compose to get things up and running.

1. Follow the `Developer Setup` instructions in [the main README](../../../README.md)


1. Bring the server up using the `ex-http` compose service
    * `docker-compose up ex-grape`
1. Make a request
    * `curl "localhost:4568/test"`
1. You should see console output for the server session
