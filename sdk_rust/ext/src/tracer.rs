use magnus::{Error, Module, RModule};
use opentelemetry::global::BoxedTracer;

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Tracer")]
pub(crate) struct Tracer(opentelemetry::global::BoxedTracer);

impl Tracer {
    pub(crate) fn new(tracer: BoxedTracer) -> Self {
        Self(tracer)
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let _class = module.define_class("Tracer", Default::default())?;
    Ok(())
}
