use magnus::{define_module, function, method, prelude::*, scan_args::scan_args, Error, Value};
use opentelemetry::trace::TracerProvider;

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::TracerProvider")]
struct WrappedTracerProvider(opentelemetry::global::GlobalTracerProvider);

impl WrappedTracerProvider {
    fn new() -> Self {
        Self(opentelemetry::global::tracer_provider())
    }

    fn tracer(&self, args: &[Value]) -> Result<Tracer, Error> {
        let args = scan_args::<(), (Option<String>, Option<String>), (), (), (), ()>(args)?;
        let (name, version) = args.optional;
        let tracer = if let Some(v) = version {
            let version = Box::leak(v.into_boxed_str());
            self.0
                .versioned_tracer(name.unwrap(), Some(version), Option::None)
        } else {
            self.0
                .versioned_tracer(name.unwrap(), Option::None, Option::None)
        };
        Ok(Tracer(tracer))
    }
}

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Tracer")]
struct Tracer(opentelemetry::global::BoxedTracer);

#[magnus::init]
fn init() -> Result<(), Error> {
    let module = define_module("OpenTelemetry")?
        .define_module("SDK")?
        .define_module("Trace")?;

    let tracer_provider_class = module.define_class("TracerProvider", Default::default())?;
    tracer_provider_class
        .define_singleton_method("new", function!(WrappedTracerProvider::new, 0))?;
    tracer_provider_class.define_method("tracer", method!(WrappedTracerProvider::tracer, -1))?;

    let _tracer_class = module.define_class("Tracer", Default::default())?;
    Ok(())
}
