---
title: Configuring automatic instrumentation
weight: 5
---

Automatic instrumentation in ruby is done via instrumentation packages, and most commonly, the `opentelemetry-instrumentation-all` package. These are called Instrumentation Libraries.

For example, if you are using Rails and enable instrumentation, your running Rails app will automatically generate telemetry data for inbound requests to your controllers.

### Configuring all instrumentation libraries

The recommended way to use instrumentation libraries is to use the `opentelemetry-instrumentation-all` package:

```console
gem 'opentelemetry-sdk'
gem 'opentelemetry-exporter-otlp'
gem 'opentelemetry-instrumentation-all'
```

and configure it early in your application lifecycle. See the example below using a Rails initializer:

```ruby
# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
OpenTelemetry::SDK.configure do |c|
  c.service_name = '<YOUR_SERVICE_NAME>'
  c.use_all() # enables all instrumentation!
end
```

This will install all instrumentation libraries and enable the ones that match up to libraries you're using in your app.

### Configuring specific instrumentation libraries

If you prefer more selectively installing and using only specific instrumentation libraries, you can do that too. For example, here's how to use only `Sinatra` and `Faraday`, with `Farady` being configured with an additional configuration parameter.

First, install the specific instrumentation libraries you know you want to use:

```console
gem install opentelemetry-instrumentation-sinatra
gem install opentelemetry-instrumentation-faraday
```

The configure them:


```ruby
require 'opentelemetry/sdk'

# install all compatible instrumentation with default configuration
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
  c.use 'OpenTelemetry::Instrumentation::Faraday', { opt: 'value' }
end
```

### Overriding configuration for specific instrumentation libraries

If you are enabling all instrumentation but want to override the configuration for a specific one, call `use_all` with a configuration parameter:

```ruby
require 'opentelemetry/sdk'

# install all compatible instrumentation with per instrumentation configuration overrides
OpenTelemetry::SDK.configure do |c|
  c.use_all('OpenTelemetry::Instrumentation::SomeInstrumentation' => { opt: 'value' })
end
```

This will configure all instrumentation libraries to be used with default values, and `SomeInstrumentation` configuration will be overridden with the value you provide.

### Next steps

Instrumentation libraries are the easiest way to generate lots of useful telemetry data about your ruby apps. But they don't generate data specific to your application's logic! To do that, you'll need to enrich the automatic instrumentation from instrumentation libraries with [manual instrumentation](manual_instrumentation.md)
