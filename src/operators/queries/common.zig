const std = @import("std");
const meta = @import("../../meta.zig");

// Testing Imports
const testing = std.testing;
const itt = @import("../../main.zig");
const TestIterator = @import("../../core.zig").TestIterator;

pub fn CommonOperators(comptime Itt: type) type {
    return struct {
        pub fn count(self: *Itt) meta.AutoReturn(Itt.ErrorSet, usize) {
            return countAs(self, usize);
        }

        pub fn countAs(self: *Itt, comptime T: type) meta.AutoReturn(Itt.ErrorSet, T) {
            defer {
                if (@hasDecl(Itt, "deinit")) {
                    self.deinit();
                }
            }

            var count_total: T = 0;

            while (true) {
                var value: ?Itt.Elem = null;

                if (Itt.ErrorSet != null) {
                    value = try self.next();
                } else {
                    value = self.next();
                }

                // When the source iterator is empty, return the previous item
                if (value == null) {
                    break;
                }

                count_total += 1;
            }

            return count_total;
        }

        pub fn reduce(self: *Itt, reducer: anytype, initial: meta.FnArgType(@TypeOf(reducer), 0)) meta.AutoReturn(Itt.ErrorSet, meta.FnReturnType(@TypeOf(reducer))) {
            defer {
                if (@hasDecl(Itt, "deinit")) {
                    self.deinit();
                }
            }

            var memo: meta.FnArgType(@TypeOf(reducer), 0) = initial;

            while (true) {
                var value: ?Itt.Elem = null;

                if (Itt.ErrorSet != null) {
                    value = try self.next();
                } else {
                    value = self.next();
                }

                // When the source iterator is empty, return the previous item
                if (value == null) {
                    break;
                }

                memo = reducer(memo, value.?);
            }

            return memo;
        }

        pub fn sum(self: *Itt) meta.AutoReturn(Itt.ErrorSet, Itt.Elem) {
            return sumAs(self, Itt.Elem);
        }

        pub fn sumAs(self: *Itt, comptime Number: type) meta.AutoReturn(Itt.ErrorSet, Number) {
            return reduce(self, struct {
                pub fn apply(acc: Number, elem: Itt.Elem) Number {
                    return acc + elem;
                }
            }.apply, 0);
        }
    };
}

test "itt count" {
    const IteratorEmpty = TestIterator(usize, .{});
    const IteratorFive = TestIterator(usize, .{ 1, 2, 3, 4, 5 });

    try testing.expect(itt.from(IteratorEmpty{}).count() == 0);
    try testing.expect(itt.from(IteratorFive{}).count() == 5);
}

test "itt reduce" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4, 5 });

    var sum = itt.from(IteratorUsize{}).reduce(struct {
        pub fn apply(memo: usize, value: usize) usize {
            return memo + value;
        }
    }.apply, 0);

    try testing.expect(sum == 15);
}

test "itt sum" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4, 5 });

    var sum = itt.from(IteratorUsize{}).sum();

    try testing.expect(sum == 15);
}
