use std::cell::{RefCell, RefMut};

use magnus::{Error, Module, RString};

use crate::error;
use crate::tokio_rb::prelude::*;
use crate::tokio_rb::{Runtime, WrappedStruct};

#[magnus::wrap(class = "Tokio::Runtime::Builder", free_immediately)]
#[derive(Debug)]
pub struct Builder {
    inner: RefCell<tokio::runtime::Builder>,
}

type RbBuilder = WrappedStruct<Builder>;

impl Builder {
    /// @yard
    /// Creates a new builder for a multi-threaded Tokio runtime.
    /// @method new_multi_thread
    /// @return [Tokio::Runtime::Builder]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Builder.html#method.new_multi_thread Rust doc
    pub fn new_multi_thread() -> Self {
        let inner = tokio::runtime::Builder::new_multi_thread();

        Self {
            inner: RefCell::new(inner),
        }
    }

    /// @yard
    /// Creates a new builder with the current thread scheduler selected.
    /// @method new_current_thread
    /// @return [Tokio::Runtime::Builder]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Builder.html#method.new_current_thread Rust doc
    pub fn new_current_thread() -> Self {
        let inner = tokio::runtime::Builder::new_current_thread();

        Self {
            inner: RefCell::new(inner),
        }
    }

    /// @yard
    /// Set maximum number of blocking threads.
    /// @method max_blocking_threads
    /// @param n [Integer]
    /// @return [Tokio::Runtime::Builder]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Builder.html#method.max_blocking_threads Rust doc
    pub fn max_blocking_threads(rb_self: RbBuilder, n: usize) -> Result<RbBuilder, Error> {
        let mut inner = rb_self.get().unwrap().inner().unwrap();
        inner.max_blocking_threads(n);

        Ok(rb_self)
    }

    /// @yard
    /// Set the name of the threads spawned by the runtime.
    /// @method thread_name
    /// @param name [String]
    /// @return [Tokio::Runtime::Builder]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Builder.html#method.thread_name Rust doc
    pub fn thread_name(rb_self: RbBuilder, val: RString) -> Result<RbBuilder, Error> {
        let mut inner = rb_self.get()?.inner()?;
        let prefix = val.to_string()?;
        inner.thread_name(&prefix);

        Ok(rb_self)
    }

    /// @yard
    /// Converts the builder into a runtime.
    /// @return [Tokio::Runtime]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Builder.html#method.build Rust doc
    pub fn build(&self) -> Result<Runtime, Error> {
        let mut inner = self.inner()?;
        let built = inner
            .enable_all()
            .build()
            .map_err(|e| error!("Failed to build runtime: {}", e))?;

        Ok(Runtime { inner: built })
    }

    fn inner(&self) -> Result<RefMut<tokio::runtime::Builder>, Error> {
        let inner = self
            .inner
            .try_borrow_mut()
            .map_err(|_| error!("Runtime is already borrowed"))?;

        Ok(inner)
    }
}

pub fn init() -> Result<(), Error> {
    let rt = crate::tokio_rb::runtime::class();
    let b = rt.define_class("Builder", Default::default())?;

    b.define_singleton_method("new_multi_thread", function!(Builder::new_multi_thread, 0))?;
    b.define_singleton_method(
        "new_current_thread",
        function!(Builder::new_current_thread, 0),
    )?;
    b.define_method("thread_name", method!(Builder::thread_name, 1))?;
    b.define_method(
        "max_blocking_threads",
        method!(Builder::max_blocking_threads, 1),
    )?;

    Ok(())
}
