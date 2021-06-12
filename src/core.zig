const std = @import("std");
const testing = std.testing;
const itt_meta = @import("./meta.zig");

/// Takes a struct and merges the declarations into one single struct
/// Currently is unused because Zig does not support creating structs
/// at comptime with dynamic declarations
pub fn MergedOperators(comptime Operators: anytype, comptime Itt: type) type {
    comptime const len = std.meta.declarations(Operators).len;

    comptime var applied_operators: [len]type = undefined;

    comptime var decls_len = 0;

    inline for (std.meta.declarations(Operators)) |decl, i| {
        const AppliedOperator = @field(Operators, decl.name)(Itt);

        applied_operators[i] = AppliedOperator;

        decls_len += std.meta.declarations(AppliedOperator).len;
    }

    comptime var decls: [decls_len]std.builtin.TypeInfo.Declaration = undefined;

    comptime var decls_cursor = 0;

    inline for (applied_operators) |AppliedOperator| {
        for (std.meta.declarations(AppliedOperator)) |decl| {
            decls[decls_cursor] = decl;
            decls_cursor += 1;
        }
    }

    return @Type(std.builtin.TypeInfo{
        .Struct = .{
            .layout = .Auto,
            .fields = &.{},
            .decls = &decls,
            .is_tuple = false,
        },
    });
}

/// Very basic structure responsible for embedding all the operators for this Iterator type
/// Should be embedded (with usingnamespace) by every operator that returns an Iterator themselves
/// See the `map` or `filter` operators for examples
pub fn IttGeneric(comptime operators: fn (type) type, comptime Itt: type) type {
    const ElemMixin = struct {
        pub const Elem = itt_meta.Elem(Itt);
    };

    const ErrorSetMixin = struct {
        pub const ErrorSet = itt_meta.ErrorSet(Itt);
    };

    return struct {
        pub const Operators = operators;

        // Elem Declaration
        pub usingnamespace if (!@hasDecl(Itt, "Elem"))
            ElemMixin
        else
            struct {};

        // ErrorSet Declaration
        pub usingnamespace if (!@hasDecl(Itt, "ErrorSet"))
            ErrorSetMixin
        else
            struct {};

        pub usingnamespace Operators(Itt);
    };
}

/// Base structure that wraps a regular iterator value (structure with a `.next()` method)
/// and in turn gives access to all the operators
/// Is itself an iterator, meaning it is fair game to call `.next()` on it or
/// at any point in the iterator chain
/// Note that here we're working directly with iterators and not iterables,
/// meaning most times, the iterator should only be iterated once
pub fn IttBase(comptime Operators: anytype, comptime SourceIterator: type) type {
    return struct {
        source: SourceIterator,

        pub const Source = SourceIterator;
        pub const Elem = itt_meta.Elem(SourceIterator);

        pub fn init(source: SourceIterator) @This() {
            return .{
                .source = source,
            };
        }

        pub fn next(self: *@This()) itt_meta.ReturnType(SourceIterator) {
            return self.source.next();
        }

        pub usingnamespace IttGeneric(Operators, @This());
    };
}

/// Utility to create a factory function for a given set of operators
/// If given an array or slice, creates an iterator structure for them automatically
/// Otherwise assumes the given value is a structure with a `.next()` method that behaves
/// like an iterator
pub fn IttFactory(comptime Operators: anytype, comptime Generators: anytype) type {
    return struct {
        pub const meta = itt_meta;

        pub usingnamespace Generators(Operators);
    };
}

/// Empty Operators list, useful to test the core facilities where we only need 
/// vanilla iterator behavior, such as calling the `.next()` method
pub fn IttEmptyOperators(comptime Itt: type) type {
    return struct {};
}

test "IttBase" {
    const IteratorUsize = TestIterator(usize, .{});
    const IttUsize = IttBase(IttEmptyOperators, IteratorUsize);

    try testing.expect(IttUsize.Source == IteratorUsize);
    try testing.expect(IttUsize.Elem == usize);

    const IteratorI32 = TestIterator(i32, .{});
    const IttI32 = IttBase(IttEmptyOperators, IteratorI32);

    try testing.expect(IttI32.Source == IteratorI32);
    try testing.expect(IttI32.Elem == i32);
}

pub fn TestIterator(comptime T: type, comptime values: anytype) type {
    return struct {
        count: usize = 0,

        pub fn next(self: *@This()) ?T {
            inline for (values) |value, i| {
                if (self.count == i) {
                    self.count += 1;

                    return values[i];
                }
            }
            return null;
        }
    };
}
