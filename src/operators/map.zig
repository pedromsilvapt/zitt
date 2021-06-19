const std = @import("std");
const meta = @import("../meta.zig");
const IttGeneric = @import("../core.zig").IttGeneric;
const FieldExpr = @import("../expr.zig").FieldExpr;
const MethodExpr = @import("../expr.zig").MethodExpr;

// Testing Imports
const testing = std.testing;
const itt = @import("../main.zig");
const TestIterator = @import("../core.zig").TestIterator;

pub fn MapOperator(comptime Itt: type) type {
    return struct {
        pub fn map(iter: Itt, transform: anytype) MapIterator(Itt, @TypeOf(transform), void) {
            return iter.mapCtx(transform, {});
        }

        pub fn mapCtx(iter: Itt, transform: anytype, ctx: anytype) MapIterator(Itt, @TypeOf(transform), @TypeOf(ctx)) {
            return MapIterator(Itt, @TypeOf(transform), @TypeOf(ctx)){
                .source = iter,
                .transform = transform,
                .context = ctx,
            };
        }

        pub fn mapField(iter: Itt, comptime field: anytype) MapFieldReturnType(field) {
            comptime const Expr = FieldExpr(Itt.Elem, field);

            return iter.mapCtx(Expr.apply, Expr{});
        }

        fn MapFieldReturnType(comptime field: anytype) type {
            comptime const Expr = FieldExpr(Itt.Elem, field);

            return MapIterator(Itt, fn (self: Itt.Elem, ctx: Expr) Expr.ReturnType, Expr);
        }

        pub fn mapMethod(iter: Itt, comptime method: anytype, args: anytype) MapMethodReturnType(method, @TypeOf(args)) {
            comptime const Expr = MethodExpr(Itt.Elem, method, @TypeOf(args));

            return iter.mapCtx(Expr.apply, Expr{ .args = args });
        }

        fn MapMethodReturnType(comptime method: anytype, comptime Args: type) type {
            comptime const Expr = MethodExpr(Itt.Elem, method, Args);

            return MapIterator(Itt, fn (self: Itt.Elem, ctx: Expr) Expr.ReturnType, Expr);
        }
    };
}

pub fn MapIterator(comptime Itt: type, comptime Transform: type, comptime Context: type) type {
    return struct {
        source: Itt,
        transform: Transform,
        context: Context,

        pub const Source = Itt;
        pub const Elem = @typeInfo(Transform).Fn.return_type.?;

        pub fn next(self: *@This()) meta.AutoReturn(Itt.ErrorSet, ?Elem) {
            // Respect source iterators that may fail
            var value_optional = if (Itt.ErrorSet != null)
                try self.source.next()
            else
                self.source.next();

            if (value_optional) |value| {
                if (Context == void) {
                    return self.transform(value);
                } else {
                    return self.transform(value, self.context);
                }
            }

            return null;
        }

        pub usingnamespace IttGeneric(Itt.Operators, @This());
    };
}

// Test functions
fn double_usize(a: usize) usize {
    return a * 2;
}

fn is_even_usize(a: usize) bool {
    return a % 2 == 0;
}

test "itt map double" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = itt.from(IteratorUsize{})
        .map(double_usize);

    try testing.expect(iterator.next().? == 2);
    try testing.expect(iterator.next().? == 4);
    try testing.expect(iterator.next().? == 6);
    try testing.expect(iterator.next().? == 8);
    try testing.expect(iterator.next() == null);
}

test "itt mapField" {
    const Struct = struct {
        value: i32,
    };

    const IteratorStruct = TestIterator(Struct, .{ Struct{ .value = 2 }, Struct{ .value = 4 } });

    var iterator = itt.from(IteratorStruct{})
        .mapField(.value);

    try testing.expect(iterator.next().? == 2);
    try testing.expect(iterator.next().? == 4);
    try testing.expect(iterator.next() == null);
}

test "itt mapMethod" {
    const Struct = struct {
        value: i32,

        pub fn add(self: @This(), n: i32) i32 {
            return self.value + n;
        }
    };

    const IteratorStruct = TestIterator(Struct, .{ Struct{ .value = 2 }, Struct{ .value = 4 } });

    var iterator = itt.from(IteratorStruct{})
        .mapMethod(.add, .{3});

    try testing.expect(iterator.next().? == 5);
    try testing.expect(iterator.next().? == 7);
    try testing.expect(iterator.next() == null);
}

test "itt map is_even" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var iterator = itt.from(IteratorUsize{})
        .map(is_even_usize);

    try testing.expect(iterator.next().? == false);
    try testing.expect(iterator.next().? == true);
    try testing.expect(iterator.next().? == false);
    try testing.expect(iterator.next().? == true);
    try testing.expect(iterator.next() == null);
}
