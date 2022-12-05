use magnus::{Error, Module, RModule};
use opentelemetry::global::BoxedSpan;

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Span")]
pub(crate) struct Span(opentelemetry::global::BoxedSpan);

impl Span {
    pub(crate) fn new(span: BoxedSpan) -> Self {
        Self(span)
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let _class = module.define_class("Span", Default::default())?;
    Ok(())
}
