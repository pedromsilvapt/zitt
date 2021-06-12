const IttBase = @import("../core.zig").IttBase;

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
