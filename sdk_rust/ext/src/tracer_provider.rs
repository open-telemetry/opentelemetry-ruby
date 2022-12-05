use crate::tracer::Tracer;
use magnus::{function, method, prelude::*, scan_args::scan_args, Error, Module, RModule, Value};
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
        Ok(Tracer::new(tracer))
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let class = module.define_class("TracerProvider", Default::default())?;
    class.define_singleton_method("new", function!(WrappedTracerProvider::new, 0))?;
    class.define_method("tracer", method!(WrappedTracerProvider::tracer, -1))?;
    Ok(())
}
