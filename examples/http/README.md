# OpenTelemetry Ruby Example

## HTTP

This is a simple example that demonstrates tracing an HTTP request from client to server. The example shows several aspects of tracing, such as:

* Using the `TracerProvider`
* Span Attributes
* Using the console exporter

### Running the example

1. Install gems
  * `bundle install`
1. Start the server from the `examples/http` directory
	* `./server.rb`
1. In a separate terminal window, run the client to make a single request:
	* `./client.rb`
1. You should see console exporter output for both the client and server sessions.

