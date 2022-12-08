use lazy_static::lazy_static;
use magnus::{define_module, function, Error, Module};
use std::io::stdout;
use tokio::runtime::Builder;

use opentelemetry::{
    global,
    runtime::{self},
    sdk::{self},
};
use opentelemetry_otlp::WithExportConfig;

mod span;
mod tracer;
mod tracer_provider;

lazy_static! {
    static ref LOCAL_RUNTIME: tokio::runtime::Runtime = Builder::new_multi_thread()
        .enable_all()
        .thread_name("tokio-worker")
        .build()
        .expect("failed to build local tokio runtime, this is a bug");
}

fn configure() -> Result<(), Error> {
    let mut tracer_provider_builder =
        sdk::trace::Builder::default().with_config(opentelemetry::sdk::trace::config());

    let env_exporters = std::env::var("OTEL_TRACES_EXPORTER").unwrap_or("".to_owned());
    for exp in env_exporters.split(",") {
        match exp {
            "otlp" => {
                // IMPORTANT: it's imperative to get a guard on a Tokio runtime before
                // using a batch exporter because OpenTelemetry needs an async runtime
                // instance in order to perform batching asynchronously. Removing this line
                // will cause a runtime panic because [there is no reactor running][1].
                //
                // [1]: https://users.rust-lang.org/t/there-is-no-reactor-running-must-be-called-from-the-context-of-a-tokio-1-x-runtime/75393
                let _guard = LOCAL_RUNTIME.enter();

                let exporter_builder: opentelemetry_otlp::SpanExporterBuilder =
                    opentelemetry_otlp::new_exporter().tonic().with_env().into();
                tracer_provider_builder = tracer_provider_builder.with_batch_exporter(
                    exporter_builder
                        .build_span_exporter()
                        .expect("failed to build otlp exporter. this is a bug."),
                    runtime::Tokio,
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

    Ok(())
}
