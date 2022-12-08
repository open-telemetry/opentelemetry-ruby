mod error;
mod helpers;
mod prelude;
mod runtime;

pub use helpers::{Wrapped, WrappedStruct};
use magnus::{define_module, gc};
pub use runtime::Runtime;

use crate::tokio_rb::prelude::*;

/// The "Tokio" Ruby module.
pub fn root() -> RModule {
    *memoize!(RModule: {
        let rmod = define_module("Tokio").unwrap();
        gc::register_mark_object(rmod);
        rmod
    })
}

#[magnus::init(name = "tokio")]
pub fn init() -> Result<(), Error> {
    error::init()?;
    runtime::init()?;

    Ok(())
}
