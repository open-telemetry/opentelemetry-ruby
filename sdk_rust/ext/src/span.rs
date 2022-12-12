use magnus::{
    class, method,
    r_hash::ForEach,
    scan_args::{get_kwargs, scan_args},
    Error, Module, RHash, RModule, Value,
};
use opentelemetry::global::BoxedSpan;

#[magnus::wrap(class = "OpenTelemetry::SDK::Trace::Span")]
pub(crate) struct Span(std::cell::RefCell<opentelemetry::global::BoxedSpan>);

pub(crate) fn magnus_value_to_otel(value: Value) -> Result<opentelemetry::Value, Error> {
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
    Ok(val)
}

impl Span {
    pub(crate) fn new(span: BoxedSpan) -> Self {
        Self(std::cell::RefCell::new(span))
    }

    fn is_recording(&self) -> bool {
        use opentelemetry::trace::Span;
        self.0.borrow().is_recording()
    }

    fn set_attribute(&self, key: String, value: Value) -> Result<(), Error> {
        use opentelemetry::trace::Span;
        Ok(self
            .0
            .borrow_mut()
            .set_attribute(opentelemetry::KeyValue::new(
                key,
                magnus_value_to_otel(value)?,
            )))
    }

    fn add_attributes(&self, attrs: RHash) -> Result<(), Error> {
        use opentelemetry::trace::Span;
        let mut v = Vec::new();
        attrs.foreach(|key: String, value: Value| {
            v.push(opentelemetry::KeyValue::new(
                key,
                magnus_value_to_otel(value)?,
            ));
            Ok(ForEach::Continue)
        })?;
        Ok(self.0.borrow_mut().set_attributes(v))
    }

    fn update_name(&self, name: String) {
        use opentelemetry::trace::Span;
        self.0.borrow_mut().update_name(name)
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
    class.define_method("recording?", method!(Span::is_recording, 0))?;
    class.define_method("set_attribute", method!(Span::set_attribute, 2))?;
    class.define_method("add_attribute", method!(Span::add_attributes, 1))?;
    class.define_method("name=", method!(Span::update_name, 1))?;
    Ok(())
}
