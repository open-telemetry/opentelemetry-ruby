use magnus::{define_module, function, Error, Module};

use opentelemetry::sdk::export::trace::stdout;

mod span;
mod tracer;
mod tracer_provider;

fn configure() -> Result<(), Error> {
    // let _ = opentelemetry_otlp::new_pipeline().tracing().install_simple()?;
    let _ = stdout::new_pipeline()
        .with_pretty_print(true)
        .install_simple();
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
