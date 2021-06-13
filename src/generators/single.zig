const IttBase = @import("../core.zig").IttBase;

// Testing Imports
const IttEmptyOperators = @import("../core.zig").IttEmptyOperators;
const testing = @import("std").testing;

pub fn SingleGenerator(comptime Operators: anytype) type {
    return struct {
        pub fn single(value: anytype) IttBase(Operators, SingleIterator(@TypeOf(value))) {
            const iter = SingleIterator(@TypeOf(value)).init(value);

            return IttBase(Operators, SingleIterator(@TypeOf(value))).init(iter);
        }
    };
}

pub fn SingleIterator(comptime Elem: type) type {
    return struct {
        element: Elem,
        finished: bool = false,

        pub fn init(element: Elem) @This() {
            return .{
                .element = element,
            };
        }

        pub fn next(self: *@This()) ?Elem {
            if (self.finished == false) {
                self.finished = true;

                return self.element;
            }

            return null;
        }
    };
}

test "Iterator single" {
    var iter = SingleGenerator(IttEmptyOperators).single(true);

    try testing.expect(iter.next().? == true);
    try testing.expect(iter.next() == null);

    iter = SingleGenerator(IttEmptyOperators).single(false);

    try testing.expect(iter.next().? == false);
    try testing.expect(iter.next() == null);
}
