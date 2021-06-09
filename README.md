# zitt
This repository contains an experimental iterator repository. Native iterators 
in Zig are considered by this library as any structure that provides a `next` 
method and that returns an optional.

This library provides a function `itt` that can be used to wrap any array, 
slice or native iterator into a chainable iterator. A Chainable Iterator also
has a method `next`, like native iterators, but provides a wealth of other base 
chainable operators such as `map`, `filter`, etc...

The library also provides a pretty straightforward way to allow the user to
include his own custom iterator operators and use them the same way as base
operators.

## Requirements
 - Zig v0.8

## Usage
```zig
const itt = @import("zitt").itt;

test {
    var array = [_]Number{
        Number{ .value = 1 },
        Number{ .value = 2 },
        Number{ .value = 3 },
    };

    var iter = itt(array)
        .mapField(.value)
        .map(square)
        .mapCtx(add, @as(i32, 2));

    try expect(iter.next().? == 3);
    try expect(iter.next().? == 6);
    try expect(iter.next().? == 11);
    try expect(iter.next() == null);
}

// Helper Declarations
pub const Number = struct { value: i32 };

pub fn square(number: i32) i32 {
    return number * number;
}

pub fn add(constant: i32, number: i32) i32 {
    return constant + number;
}
```

## Custom Operators
```zig
const IttGeneric = @import("zitt").IttGeneric;

/// First we need to create a new operator. Usually each operator can have one
/// or more chainable functions (in this case, one called `take`) and a 
/// Chainable Iterator that is returned by calling the operator function.
fn MyCustomTakeOperator(comptime Itt: type) type {
    return struct {
        pub fn take(self: Itt, number: usize) Iterator {
            return Iterator{ .source = self, .number = number };
        }

        /// Note that this is not public, because we do not want this declaration
        /// being available after calling itt, like `itt(...).Iterable`
        /// If we want our iterable to be accessible to the outside world, we can
        /// declare it as a generic function outside the operator
        const Iterator = struct {
            /// The iterator almost always has the field `source: Itt`, followed
            /// by the operator-specific fields.
            source: Itt,
            number: usize,
            consumed: usize = 0,

            /// Each chainable iterator also needs two public declarations
            /// The source type, and the Elem type
            pub const Source = Itt;
            /// In this case we can just reuse the element from our Source type
            /// Because we will not change the type of the values returned
            /// by the iterator, just how many values are returned
            pub const Elem = Itt.Elem;

            /// The final piece required of each iterator is, of course, the
            /// `next` method. It should always receive only a pointer to itself,
            /// and return an optional Elem
            pub fn next(self: *Iterator) ?Elem {
                if (self.consumed < self.number) {
                    self.consumed += 1;

                    // Note that if our `self.number` is bigger than the amount
                    // of elements in the source iterator, we are going to be
                    // calling `source.next` multiple times after the iterator
                    // has been exhausted/emptied. This is fine because all
                    // iterators should return null all the time after being
                    // emptied, and in this case we can take advantage of that
                    return self.source.next();
                }

                return null;
            }

            /// Finally, we need to import our utility IttGeneric, by passing
            /// operators currently being used, as well as this very own
            /// iterator type. This is what allows all operators to be chainable
            pub usingnamespace IttGeneric(Itt.Operators, Iterator);
        };
    };
}

// Now that our custom operator and iterator has been created, we can create
// our very own `itt` function with all the base operators, if we want so,
// as well as all of our custom operators (in this case, MyCustomTakeOperator)
const IttFactory = @import("zitt").IttFactory;
const IttBaseOperators = @import("zitt").IttBaseOperators;

/// This function merges the base operators as well as our custom operator
/// Note that this is a generic function, just like our operator. This is 
/// because all operators are instanced for every type of source operator they
/// are called for. This has some neat advantages, such as being able to declare
/// different operators for different sources (for example, have a `sum()` be
/// available only for cases when Itt.Elem is a numeric type).
fn IttCustomOperators(comptime Itt: type) type {
    return struct {
        pub usingnamespace IttBaseOperators(Itt);
        pub usingnamespace MyCustomTakeOperator(Itt);
    };
}

/// Create the wrapper function, by giving it the operators
const itt = IttFactory(IttCustomOperators).itt;

test {
    var array = [_]Number{
        Number{ .value = 1 },
        Number{ .value = 2 },
        Number{ .value = 3 },
    };

    var iter = itt(array).take(2);

    try expect(iter.next().?.value == 1);
    try expect(iter.next().?.value == 2);
    try expect(iter.next() == null);
}
```

## Architecture
Right now this library is pretty comptime heavy, I figure, and honestly I'm not 
yet sure if it is a lucky stroke of genius or a Frankenstein-like work.

Regardless, if you've got any comments or suggestions for it, please do
let me know! :)

## Building/Testing
To build and/or run the tests, just execute either of the following commands:
```bash
zig build
zig build test
```