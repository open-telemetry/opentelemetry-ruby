use crate::span::{magnus_value_to_otel, Span};
use magnus::{
    method,
    r_hash::ForEach,
    scan_args::{get_kwargs, scan_args},
    Error, Module, RArray, RHash, RModule, Symbol, Value,
};
use opentelemetry::{global::BoxedTracer, trace::OrderMap};
#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Tracer")]
pub(crate) struct Tracer(opentelemetry::global::BoxedTracer);

impl Tracer {
    pub(crate) fn new(tracer: BoxedTracer) -> Self {
        Self(tracer)
    }

    fn start_span(&self, args: &[Value]) -> Result<Span, Error> {
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
        let (_with_parent, attributes, _links, _start_timestamp, _kind): (
            Option<Value>,
            Option<RHash>,
            Option<RArray>,
            Option<Value>,
            Option<Symbol>,
        ) = args.optional;
        let _: () = args.splat;

        let mut builder = self.0.span_builder(name);
        if let Some(attrs) = attributes {
            let mut map = OrderMap::with_capacity(attrs.len());
            attrs.foreach(|key: String, value: Value| {
                map.insert(key.into(), magnus_value_to_otel(value)?);
                Ok(ForEach::Continue)
            })?;
            builder = builder.with_attributes_map(map);
        }
        // TODO: with_parent and friends
        Ok(Span::new(builder.start(&self.0)))
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let class = module.define_class("Tracer", Default::default())?;
    class.define_method("start_span", method!(Tracer::start_span, -1))?;
    Ok(())
}
