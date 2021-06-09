const std = @import("std");
const testing = std.testing;

const ArrayIterator = @import("./iterators/array.zig").ArrayIterator;
const SliceIterator = @import("./iterators/slice.zig").SliceIterator;

pub fn TypeOfIterator(comptime Iter: type) type {
    comptime const nextDecl = std.meta.declarationInfo(Iter, "next");

    if (comptime nextDecl.data != .Fn) {
        @compileError("Iterator 'next' declaration is not a function");
    }

    return std.meta.Child(nextDecl.data.Fn.return_type);
}

test "TypeOfIterator" {
    try testing.expect(TypeOfIterator(TestIterator(usize, .{})) == usize);
    try testing.expect(TypeOfIterator(TestIterator(i32, .{})) == i32);
    try testing.expect(TypeOfIterator(TestIterator(i32, .{})) != usize);
}

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
    return struct {
        pub const Operators = operators;

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
        pub const Elem = TypeOfIterator(SourceIterator);

        pub fn init(source: SourceIterator) @This() {
            return .{
                .source = source,
            };
        }

        pub fn next(self: *@This()) ?Elem {
            return self.source.next();
        }

        pub usingnamespace IttGeneric(Operators, @This());
    };
}

/// Infers the iterator type for a given value type.
/// If given an array or slice, creates an iterator type for them sepcifically
/// Otherwise assumes the given value is a structure with a `.next()` method that behaves
/// like an iterator
pub fn InferredIteratorType(comptime Src: type) type {
    const type_info = @typeInfo(Src);

    if (type_info == .Array) {
        return ArrayIterator(type_info.Array.child, type_info.Array.len);
    } else if (type_info == .Pointer and type_info.Pointer.size == .Slice) {
        return SliceIterator(type_info.Pointer.child);
    } else {
        return Src;
    }
}

/// Utility to create a factory function for a given set of operators
/// If given an array or slice, creates an iterator structure for them automatically
/// Otherwise assumes the given value is a structure with a `.next()` method that behaves
/// like an iterator
pub fn IttFactory(comptime Operators: anytype) type {
    return struct {
        pub fn itt(src: anytype) IttBase(Operators, InferredIteratorType(@TypeOf(src))) {
            var iter: InferredIteratorType(@TypeOf(src)) = undefined;

            const type_info = @typeInfo(@TypeOf(src));

            if (type_info == .Array) {
                iter = ArrayIterator(type_info.Array.child, type_info.Array.len).init(src);
            } else if (type_info == .Pointer and type_info.Pointer.size == .Slice) {
                iter = SliceIterator(type_info.Pointer.child).init(src);
            } else {
                iter = src;
            }

            return IttBase(Operators, InferredIteratorType(@TypeOf(src))).init(iter);
        }
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

test "IttFactory" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });
    const itt = IttFactory(IttEmptyOperators).itt;

    var iter = itt(IteratorUsize{});

    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 3);
    try testing.expect(iter.next().? == 4);
    try testing.expect(iter.next() == null);
}

test "IttFactory array" {
    const itt = IttFactory(IttEmptyOperators).itt;

    const array = [_]usize{ 1, 2, 3, 4 };

    var iter = itt(array);

    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 3);
    try testing.expect(iter.next().? == 4);
    try testing.expect(iter.next() == null);
}

test "IttFactory slice" {
    const itt = IttFactory(IttEmptyOperators).itt;

    const array = [_]usize{ 1, 2, 3, 4 };

    var iter = itt(@as([]const usize, &array));

    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 3);
    try testing.expect(iter.next().? == 4);
    try testing.expect(iter.next() == null);
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
