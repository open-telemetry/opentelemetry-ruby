use magnus::Error;

use crate::tokio_rb::prelude::*;
use crate::tokio_rb::runtime;

/// @yard
/// @rename Tokio::EnterGuard
/// Represents a Tokio EnterGuard.
/// @see https://docs.rs/tokio/latest/tokio/EnterGuard/struct.EnterGuard.html Rust doc
#[derive(Debug)]
pub struct EnterGuard<'a> {
    #[allow(dead_code)]
    inner: tokio::runtime::EnterGuard<'a>,
}

unsafe impl<'a> TypedData for EnterGuard<'a> {
    fn class() -> magnus::RClass {
        *memoize!(RClass: runtime::class().define_class("EnterGuard", Default::default()).unwrap())
    }

    fn data_type() -> &'static magnus::DataType {
        memoize!(magnus::DataType: {
            let mut builder = DataTypeBuilder::<EnterGuard>::new("Tokio::Runtime::EnterGuard");
            builder.free_immediately();
            builder.build()
        })
    }
}

impl DataTypeFunctions for EnterGuard<'_> {}

impl<'a> EnterGuard<'a> {
    #[allow(dead_code)]
    pub fn new(inner: tokio::runtime::EnterGuard<'a>) -> Result<Self, Error> {
        Ok(Self { inner })
    }
}

pub fn init() -> Result<(), Error> {
    runtime::class().define_class("EnterGuard", Default::default())?;

    Ok(())
}
