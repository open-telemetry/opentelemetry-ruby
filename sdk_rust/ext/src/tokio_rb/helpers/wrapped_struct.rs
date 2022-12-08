use std::marker::PhantomData;
use std::ops::Deref;

use magnus::error::Error;
use magnus::value::Value;
use magnus::{exception, gc, RTypedData, TryConvert, TypedData};

/// A small wrapper for `RTypedData` that keeps track of the concrete struct
/// type, and the underlying [`Value`] for GC purposes.
#[derive(Debug)]
#[repr(transparent)]
pub struct WrappedStruct<T: TypedData> {
    inner: RTypedData,
    phantom: PhantomData<T>,
}

impl<T: TypedData> Clone for WrappedStruct<T> {
    fn clone(&self) -> Self {
        Self {
            inner: self.inner,
            phantom: PhantomData,
        }
    }
}
impl<T: TypedData> Copy for WrappedStruct<T> {}

impl<T: TypedData> WrappedStruct<T> {
    /// Gets the underlying struct.
    pub fn get(&self) -> Result<&T, Error> {
        self.inner.try_convert()
    }

    /// Get the Ruby [`Value`] for this struct.
    pub fn to_value(self) -> Value {
        self.inner.into()
    }

    /// Marks the Ruby [`Value`] for GC.
    pub fn mark(&self) {
        gc::mark(&self.inner.into());
    }
}

impl<T: TypedData> From<WrappedStruct<T>> for Value {
    fn from(wrapped_struct: WrappedStruct<T>) -> Self {
        wrapped_struct.to_value()
    }
}

impl<T: TypedData> Deref for WrappedStruct<T> {
    type Target = RTypedData;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl<T: TypedData> From<T> for WrappedStruct<T> {
    fn from(t: T) -> Self {
        Self {
            inner: RTypedData::wrap(t),
            phantom: PhantomData,
        }
    }
}

impl<T> TryConvert for WrappedStruct<T>
where
    T: TypedData,
{
    fn try_convert(val: Value) -> Result<Self, Error> {
        let inner = RTypedData::from_value(val).ok_or_else(|| {
            Error::new(
                exception::type_error(),
                format!(
                    "no implicit conversion of {} into {}",
                    unsafe { val.classname() },
                    T::class()
                ),
            )
        })?;

        Ok(Self {
            inner,
            phantom: PhantomData,
        })
    }
}

pub trait Wrapped<T: TypedData> {
    /// Convert the typed struct into a [`WrappedStruct`], which makes it usable
    /// from Ruby.
    fn to_ruby_value(self) -> WrappedStruct<T>;
}

impl<T: TypedData> Wrapped<T> for T {
    fn to_ruby_value(self) -> WrappedStruct<T> {
        WrappedStruct::from(self)
    }
}
