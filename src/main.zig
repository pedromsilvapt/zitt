const std = @import("std");
const testing = std.testing;
const root = @import("root");

pub const IttBase = @import("./core.zig").IttBase;
pub const IttGeneric = @import("./core.zig").IttGeneric;
pub const IttFactory = @import("./core.zig").IttFactory;

// Base Generators
pub fn IttBaseGenerators(comptime Operators: anytype) type {
    return struct {
        pub usingnamespace @import("./generators/from.zig").FromGenerator(Operators);
        pub usingnamespace @import("./generators/single.zig").SingleGenerator(Operators);
        pub usingnamespace @import("./generators/fail.zig").FailGenerator(Operators);

        pub usingnamespace if (@hasDecl(root, "IttCustomGenerators"))
            root.IttCustomGenerators(Itt)
        else
            struct {};
    };
}

pub fn IttBaseOperators(comptime Itt: type) type {
    return struct {
        pub usingnamespace @import("./operators/map.zig").MapOperator(Itt);
        pub usingnamespace @import("./operators/filter.zig").FilterOperator(Itt);

        pub usingnamespace if (@hasDecl(root, "IttCustomOperators"))
            root.IttCustomOperators(Itt)
        else
            struct {};
    };
}

pub usingnamespace IttFactory(IttBaseOperators, IttBaseGenerators);

// Test functions
fn double_usize(a: usize) usize {
    return a * 2;
}

fn is_even_usize(a: usize) bool {
    return a % 2 == 0;
}

const TestIterator = @import("./core.zig").TestIterator;

test "IttFactory from" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iter = from(IteratorUsize{});

    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 3);
    try testing.expect(iter.next().? == 4);
    try testing.expect(iter.next() == null);
}

test "IttFactory from array" {
    const array = [_]usize{ 1, 2, 3, 4 };

    var iter = from(array);

    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 3);
    try testing.expect(iter.next().? == 4);
    try testing.expect(iter.next() == null);
}

test "IttFactory from slice" {
    const array = [_]usize{ 1, 2, 3, 4 };

    var iter = from(@as([]const usize, &array));

    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 3);
    try testing.expect(iter.next().? == 4);
    try testing.expect(iter.next() == null);
}

test "IttFactory single" {
    var iter = single(true);

    try testing.expect(iter.next().? == true);
    try testing.expect(iter.next() == null);

    iter = single(false);

    try testing.expect(iter.next().? == false);
    try testing.expect(iter.next() == null);
}

test "IttFactory fail" {
    var iter = fail(error.CustomError);

    try testing.expectError(error.CustomError, iter.next());
    try testing.expectError(error.CustomError, iter.next());
}

test "itt map double" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = from(IteratorUsize{})
        .map(double_usize);

    try std.testing.expect(iterator.next().? == 2);
    try std.testing.expect(iterator.next().? == 4);
    try std.testing.expect(iterator.next().? == 6);
    try std.testing.expect(iterator.next().? == 8);
    try std.testing.expect(iterator.next() == null);
}

test "itt map is_even" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = from(IteratorUsize{})
        .map(is_even_usize);

    try std.testing.expect(iterator.next().? == false);
    try std.testing.expect(iterator.next().? == true);
    try std.testing.expect(iterator.next().? == false);
    try std.testing.expect(iterator.next().? == true);
    try std.testing.expect(iterator.next() == null);
}

test "itt filter is_even" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = from(IteratorUsize{})
        .filter(is_even_usize);

    try std.testing.expect(iterator.next().? == 2);
    try std.testing.expect(iterator.next().? == 4);
    try std.testing.expect(iterator.next() == null);
}
