const IttBase = @import("../core.zig").IttBase;

// Testing Imports
const std = @import("std");
const IttEmptyOperators = @import("../core.zig").IttEmptyOperators;
const testing = @import("std").testing;

pub fn RangeGenerator(comptime Operators: anytype) type {
    return struct {
        pub fn range(comptime Elem: type, start: Elem, end: Elem, step: Elem) IttBase(Operators, RangeIterator(Elem)) {
            const iter = RangeIterator(Elem).init(start, end, step);

            return IttBase(Operators, RangeIterator(Elem)).init(iter);
        }
    };
}

pub fn RangeIterator(comptime Elem: type) type {
    return struct {
        start: Elem,
        end: Elem,
        step: Elem,
        current: Elem,

        pub fn init(start: Elem, end: Elem, step: Elem) @This() {
            return .{
                .start = start,
                .end = end,
                .step = step,
                .current = start,
            };
        }

        pub fn next(self: *@This()) ?Elem {
            var in_range: bool = undefined;

            if (self.step >= 0) {
                // Increasing Range
                in_range = self.current < self.end;
            } else {
                // Decreasing Range
                in_range = self.current > self.end;
            }

            if (in_range) {
                var result: Elem = undefined;

                if (@typeInfo(Elem) == .Int) {
                    if (@addWithOverflow(Elem, self.current, self.step, &result)) {
                        // If overflowed
                        result = self.end;
                    }
                } else if (@typeInfo(Elem) == .Float) {
                    result = self.current + self.step;
                } else {
                    @compileError("Expected range type to be either Int or Float, instead got " ++ @tagName(@typeInfo(Elem)));
                }

                defer self.current = result;

                return self.current;
            }

            return null;
        }
    };
}

test "Iterator range i32" {
    var iter = RangeGenerator(IttEmptyOperators).range(i32, 0, 2, 1);

    try testing.expect(iter.next().? == 0);
    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next() == null);

    iter = RangeGenerator(IttEmptyOperators).range(i32, 2, 0, -1);

    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next() == null);
}

test "Iterator range i32 overflow" {
    const max = std.math.maxInt(i32);

    var iter = RangeGenerator(IttEmptyOperators).range(i32, max - 3, max, 2);

    try testing.expect(iter.next().? == max - 3);
    try testing.expect(iter.next().? == max - 1);
    try testing.expect(iter.next() == null);
}

test "Iterator range f64" {
    var iter = RangeGenerator(IttEmptyOperators).range(f64, 0, 2, 0.5);

    try testing.expect(iter.next().? == 0);
    try testing.expect(iter.next().? == 0.5);
    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 1.5);
    try testing.expect(iter.next() == null);

    iter = RangeGenerator(IttEmptyOperators).range(f64, 2, 0, -0.5);

    try testing.expect(iter.next().? == 2);
    try testing.expect(iter.next().? == 1.5);
    try testing.expect(iter.next().? == 1);
    try testing.expect(iter.next().? == 0.5);
    try testing.expect(iter.next() == null);
}
