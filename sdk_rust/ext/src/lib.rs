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
        match (name, version) {
            (Some(n), Some(v)) => {
                let version = Box::leak(v.into_boxed_str());
                let tracer = self.0.versioned_tracer(n, Some(version), Option::None);
                Ok(Tracer(tracer))
            }
            (Some(n), None) => {
                let tracer = self.0.versioned_tracer(n, Option::None, Option::None);
                Ok(Tracer(tracer))
            }
            (None, None) => {
                let tracer = self.0.versioned_tracer("", Option::None, Option::None);
                Ok(Tracer(tracer))
            }
            _ => Err(Error::runtime_error("version supplied without name")),
        }
        // Box::leak(s.into_boxed_str())
        // let tracer = self
        //     .0
        //     .versioned_tracer(name.unwrap(), version.as_deref(), Option::None);
        // Ok(Tracer(tracer))
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
