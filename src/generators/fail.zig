const IttBase = @import("../core.zig").IttBase;
// Testing Imports
const IttEmptyOperators = @import("../core.zig").IttEmptyOperators;
const testing = @import("std").testing;

pub fn FailGenerator(comptime Operators: anytype) type {
    return struct {
        pub fn fail(value: anytype) IttBase(Operators, FailIterator(@TypeOf(value))) {
            const iter = FailIterator(@TypeOf(value)).init(value);

            return IttBase(Operators, FailIterator(@TypeOf(value))).init(iter);
        }
    };
}

pub fn FailIterator(comptime ErrorSet: type) type {
    return struct {
        error_value: ErrorSet,

        pub fn init(error_value: ErrorSet) @This() {
            return .{
                .error_value = error_value,
            };
        }

        pub fn next(self: *@This()) ErrorSet!?void {
            return self.error_value;
        }
    };
}

test "IttFactory fail" {
    var iter = FailGenerator(IttEmptyOperators).fail(error.CustomError);

    try testing.expectError(error.CustomError, iter.next());
    try testing.expectError(error.CustomError, iter.next());
}
