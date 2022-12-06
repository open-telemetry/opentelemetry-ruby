use crate::span::Span;
use magnus::{
    method,
    scan_args::{get_kwargs, scan_args},
    Error, Module, RArray, RHash, RModule, Symbol, Value,
};
use opentelemetry::global::BoxedTracer;
#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Tracer")]
pub(crate) struct Tracer(opentelemetry::global::BoxedTracer);

impl Tracer {
    pub(crate) fn new(tracer: BoxedTracer) -> Self {
        Self(tracer)
    }

    pub(crate) fn start_span(&self, args: &[Value]) -> Result<Span, Error> {
        use opentelemetry::trace::Tracer;
        let args = scan_args::<(String,), (), (), (), _, ()>(args)?;
        let (name,) = args.required;
        let args = get_kwargs(
            args.keywords,
            &[],
            &[
                "with_parent",
                "attributes",
                "links",
                "start_timestamp",
                "kind",
            ],
        )?;
        let _: () = args.required;
        let (_with_parent, _attributes, _links, _start_timestamp, _kind): (
            Option<Value>,
            Option<RHash>,
            Option<RArray>,
            Option<Value>,
            Option<Symbol>,
        ) = args.optional;
        let _: () = args.splat;

        let builder = self.0.span_builder(name);
        // TODO: with_parent and friends
        Ok(Span::new(builder.start(&self.0)))
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let class = module.define_class("Tracer", Default::default())?;
    class.define_method("start_span", method!(Tracer::start_span, -1))?;
    Ok(())
}
