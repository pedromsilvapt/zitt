pub const std = @import("std");
pub const IttBase = @import("./core.zig").IttBase;
pub const IttGeneric = @import("./core.zig").IttGeneric;
pub const IttFactory = @import("./core.zig").IttFactory;

pub fn IttBaseOperators(comptime Itt: type) type {
    return struct {
        pub usingnamespace @import("./operators/map.zig").MapOperator(Itt);
        pub usingnamespace @import("./operators/filter.zig").FilterOperator(Itt);
    };
}

pub const itt = IttFactory(IttBaseOperators).itt;

// Test functions
fn double_usize(a: usize) usize {
    return a * 2;
}

fn is_even_usize(a: usize) bool {
    return a % 2 == 0;
}

const TestIterator = @import("./core.zig").TestIterator;

test "itt map double" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = itt(IteratorUsize{})
        .map(double_usize);

    try std.testing.expect(iterator.next().? == 2);
    try std.testing.expect(iterator.next().? == 4);
    try std.testing.expect(iterator.next().? == 6);
    try std.testing.expect(iterator.next().? == 8);
    try std.testing.expect(iterator.next() == null);
}

test "itt map is_even" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = itt(IteratorUsize{})
        .map(is_even_usize);

    try std.testing.expect(iterator.next().? == false);
    try std.testing.expect(iterator.next().? == true);
    try std.testing.expect(iterator.next().? == false);
    try std.testing.expect(iterator.next().? == true);
    try std.testing.expect(iterator.next() == null);
}

test "itt filter is_even" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = itt(IteratorUsize{})
        .filter(is_even_usize);

    try std.testing.expect(iterator.next().? == 2);
    try std.testing.expect(iterator.next().? == 4);
    try std.testing.expect(iterator.next() == null);
}
