use magnus::{
    method,
    scan_args::{get_kwargs, scan_args},
    Error, Module, RModule, Value,
};
use opentelemetry::global::BoxedSpan;

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Span")]
pub(crate) struct Span(std::cell::RefCell<opentelemetry::global::BoxedSpan>);

impl Span {
    pub(crate) fn new(span: BoxedSpan) -> Self {
        Self(std::cell::RefCell::new(span))
    }

    fn finish(&self, args: &[Value]) -> Result<(), Error> {
        use opentelemetry::trace::Span;
        let args = scan_args::<(), (), (), (), _, ()>(args)?;
        let args = get_kwargs(args.keywords, &[], &["end_timestamp"])?;
        let _: () = args.required;
        let (end_timestamp,): (Option<Value>,) = args.optional;
        let _: () = args.splat;
        if end_timestamp.is_none() {
            self.0.borrow_mut().end();
        } else {
            todo!()
        }
        Ok(())
    }
}

pub(crate) fn init(module: RModule) -> Result<(), Error> {
    let class = module.define_class("Span", Default::default())?;
    class.define_method("finish", method!(Span::finish, -1))?;
    Ok(())
}
