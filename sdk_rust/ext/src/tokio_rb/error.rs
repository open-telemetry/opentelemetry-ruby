use magnus::exception::standard_error;
use magnus::ExceptionClass;

use crate::tokio_rb::prelude::*;

/// Base error class for all Tokio errors.
pub fn base_error() -> ExceptionClass {
    *memoize!(ExceptionClass: root().define_error("Error", standard_error()).unwrap())
}

/// Macro to create a new Tokio error with a formatted message.
#[macro_export]
macro_rules! error {
    ($($arg:expr),*) => {
        magnus::Error::new($crate::tokio_rb::error::base_error(), format!($($arg),*))
    };
}

pub fn init() -> Result<(), Error> {
    let _ = base_error();

    Ok(())
}
