# OpenTelemetry Ruby Example

## HTTP

This is a simple example that demonstrates tracing an HTTP request from client to server. The example shows several aspects of tracing, such as:

* Using the `TracerProvider`
* Span Attributes
* Using the console exporter

### Running the example

Install gems

```sh
bundle install
```

Start the server

```sh
ruby server.rb
```

In a separate terminal window, run the client to make a single request:

```sh
ruby client.rb
```

You should see console exporter output for both the client and server sessions.
