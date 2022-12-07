use crate::tracer::Tracer;
use magnus::{
    function, method,
    prelude::*,
    scan_args::{get_kwargs, scan_args},
    Error, Module, RModule, Value,
};

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::TracerProvider")]
struct TracerProvider(opentelemetry::global::GlobalTracerProvider);

impl TracerProvider {
    fn new() -> Self {
        Self(opentelemetry::global::tracer_provider())
    }

    fn tracer(&self, args: &[Value]) -> Result<Tracer, Error> {
        use opentelemetry::trace::TracerProvider;
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

    fn shutdown(&self, args: &[Value]) -> Result<(), Error> {
        let args = scan_args::<(), (), (), (), _, ()>(args)?;
        let args = get_kwargs(args.keywords, &[], &["timeout"])?;
        let _: () = args.required;
        let (_timeout,): (Option<Value>,) = args.optional;
        let _: () = args.splat;
        opentelemetry::global::shutdown_tracer_provider();
        Ok(())
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let class = module.define_class("TracerProvider", Default::default())?;
    class.define_singleton_method("new", function!(TracerProvider::new, 0))?;
    class.define_method("tracer", method!(TracerProvider::tracer, -1))?;
    class.define_method("shutdown", method!(TracerProvider::shutdown, -1))?;
    Ok(())
}
