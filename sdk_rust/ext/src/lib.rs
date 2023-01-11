use magnus::{define_module, function, Error, Module};
use std::io::stdout;

use opentelemetry::{
    global,
    runtime::{self as otel_runtime},
    sdk::{self},
};
use opentelemetry_otlp::WithExportConfig;

mod span;
mod tokio_rb; // TODO(wperron): this should be in its own crate
mod tracer;
mod tracer_provider;

fn configure() -> Result<(), Error> {
    println!("[RUST] configure");

    let mut tracer_provider_builder =
        sdk::trace::Builder::default().with_config(opentelemetry::sdk::trace::config());

    let env_exporters = std::env::var("OTEL_TRACES_EXPORTER").unwrap_or("".to_owned());
    for exp in env_exporters.split(",") {
        match exp {
            "otlp" => {
                let exporter_builder: opentelemetry_otlp::SpanExporterBuilder =
                    opentelemetry_otlp::new_exporter().tonic().with_env().into();
                tracer_provider_builder = tracer_provider_builder.with_batch_exporter(
                    exporter_builder
                        .build_span_exporter()
                        .expect("failed to build otlp exporter. this is a bug."),
                    otel_runtime::Tokio,
                );
            }
            "console" => {
                let exporter = sdk::export::trace::stdout::Exporter::new(stdout(), false);
                tracer_provider_builder = tracer_provider_builder.with_simple_exporter(exporter);
            }
            _ => {}
        }
    }

    let provider = tracer_provider_builder.build();
    global::set_tracer_provider(provider);
    Ok(())
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let sdk = define_module("OpenTelemetry")?.define_module("SDK")?;
    let module = sdk.define_module("Trace")?;

    sdk.define_module_function("configure", function!(configure, 0))?;

    tracer_provider::init(module)?;
    tracer::init(module)?;
    span::init(module)?;

    tokio_rb::init()?;

    Ok(())
}
