use magnus::{define_module, Error, Module};

mod tracer;
mod tracer_provider;

#[magnus::init]
fn init() -> Result<(), Error> {
    let module = define_module("OpenTelemetry")?
        .define_module("SDK")?
        .define_module("Trace")?;

    tracer_provider::init(module)?;
    tracer::init(module)?;

    Ok(())
}
