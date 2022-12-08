mod builder;
mod enter_guard;
mod handle;

use magnus::block::{block_given, yield_value};

use self::builder::Builder;
use crate::tokio_rb::prelude::*;

/// @yard
/// @rename Tokio::Runtime
/// Represents a Tokio runtime.
/// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html Rust doc
#[derive(Debug)]
pub struct Runtime {
    inner: tokio::runtime::Runtime,
}

unsafe impl TypedData for Runtime {
    fn class() -> magnus::RClass {
        *memoize!(RClass: root().define_class("Runtime", Default::default()).unwrap())
    }

    fn data_type() -> &'static magnus::DataType {
        memoize!(magnus::DataType: {
            let mut builder = DataTypeBuilder::<Runtime>::new("Tokio::Runtime");
            builder.free_immediately();
            builder.build()
        })
    }
}

impl DataTypeFunctions for Runtime {}

impl Runtime {
    /// @yard
    /// Creates a new multi-threaded Tokio runtime.
    ///
    /// Suitable for providing a runtime for executing tasks that do not require
    /// Ruby access (i.e. telemetry for Rust crates).
    ///
    /// As of now, it is **not safe** to send execute any Ruby code in this
    /// runtime. There are no built-in synchronization mechanisms to prevent
    /// this. Doing so will likely segfault your program.
    ///
    /// @method new
    /// @return [Tokio::Runtime]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html#method.new Rust doc
    pub fn new() -> Result<Self, Error> {
        if block_given() {
            let builder = Builder::new_multi_thread().to_ruby_value();
            let _ = yield_value::<_, Value>(builder)?;
            builder.get()?.build()
        } else {
            Builder::new_multi_thread().build()
        }
    }

    /// @yard
    /// Enters the runtime context so that Tokio tasks can be spawned within it.
    /// @method enter
    /// @yield [Tokio::Runtime::EnterGuard]
    /// @return [NilClass]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html#method.enter Rust doc
    pub fn enter(&self) -> Result<Value, Error> {
        let ret = {
            let _inner_guard = self.inner.enter();
            yield_value(())
        }?;

        Ok(ret)
    }
}

/// The "Tokio::Runtime" Ruby class.
pub fn class() -> RClass {
    *memoize!(RClass: {
        crate::tokio_rb::root().define_class("Runtime", Default::default()).unwrap()
    })
}

pub fn init() -> Result<(), Error> {
    builder::init()?;

    let klass = class();
    klass.define_singleton_method("new", function!(Runtime::new, 0))?;
    klass.define_method("enter", method!(Runtime::enter, 0))?;

    handle::init()?;
    enter_guard::init()?;

    Ok(())
}
