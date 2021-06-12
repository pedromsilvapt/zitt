const IttBase = @import("../core.zig").IttBase;

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
