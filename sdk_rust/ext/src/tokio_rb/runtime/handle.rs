use magnus::{Error, Symbol};
use tokio::runtime::RuntimeFlavor;

use crate::error;
use crate::tokio_rb::prelude::*;
use crate::tokio_rb::runtime;

/// @yard
/// Represents a Tokio runtime handle.
/// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html Rust doc
#[magnus::wrap(class = "Tokio::Runtime::Handle")]
#[derive(Debug)]
pub struct Handle {
    inner: tokio::runtime::Handle,
}

impl Handle {
    /// @yard
    /// Gets a handle to the current runtime.
    /// @method current
    /// @return [Tokio::Runtime::Handle]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html#method.current Rust doc
    pub fn current() -> Result<Self, Error> {
        let inner = tokio::runtime::Handle::try_current().map_err(|e| error!("{}", e))?;

        Ok(Self { inner })
    }

    /// @yard
    /// Get the runtime's flavor (:current_thread or :multi_thread).
    /// @method runtime_flavor
    /// @return [Symbol]
    /// @see https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html#method.runtime_flavor Rust doc
    pub fn runtime_flavor(&self) -> Result<Symbol, Error> {
        let flavor = self.inner.runtime_flavor();
        let flavor = match flavor {
            RuntimeFlavor::CurrentThread => "current_thread",
            RuntimeFlavor::MultiThread => "multi_thread",
            _ => return Err(error!("Unknown runtime flavor")),
        };

        Ok(Symbol::from(flavor))
    }
}

pub fn init() -> Result<(), Error> {
    let klass = runtime::class().define_class("Handle", Default::default())?;
    klass.define_singleton_method("current", function!(Handle::current, 0))?;
    klass.define_method("runtime_flavor", method!(Handle::runtime_flavor, 0))?;

    Ok(())
}
