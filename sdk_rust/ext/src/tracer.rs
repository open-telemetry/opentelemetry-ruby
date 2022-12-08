use crate::span::Span;
use magnus::{
    class, method,
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
                let cls = value.class();
                let val = if cls.equal(class::true_class())? {
                    opentelemetry::Value::Bool(true)
                } else if cls.equal(class::false_class())? {
                    opentelemetry::Value::Bool(false)
                } else if cls.equal(class::integer())? {
                    opentelemetry::Value::I64(value.try_convert().unwrap())
                } else if cls.equal(class::float())? {
                    opentelemetry::Value::F64(value.try_convert().unwrap())
                } else if cls.equal(class::string())? {
                    opentelemetry::Value::String(value.try_convert::<String>().unwrap().into())
                } else {
                    todo!() // Array
                };
                map.insert(key.into(), val);
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
