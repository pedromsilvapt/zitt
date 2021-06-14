const std = @import("std");
const meta = @import("../../meta.zig");

// Testing Imports
const testing = std.testing;
const itt = @import("../../main.zig");
const TestIterator = @import("../../core.zig").TestIterator;

pub fn PositionalOperators(comptime Itt: type) type {
    return struct {
        pub fn first(self: *Itt) meta.AutoReturn(Itt.ErrorSet, ?Itt.Elem) {
            defer {
                if (@hasDecl(Itt, "deinit")) {
                    self.deinit();
                }
            }

            if (Itt.ErrorSet != null) {
                return try self.next();
            } else {
                return self.next();
            }
        }

        pub fn last(self: *Itt) meta.AutoReturn(Itt.ErrorSet, ?Itt.Elem) {
            defer {
                if (@hasDecl(Itt, "deinit")) {
                    self.deinit();
                }
            }

            var previous_value: ?Itt.Elem = null;

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

                previous_value = value;
            }

            return previous_value;
        }

        pub fn at(self: *Itt, index: usize) meta.AutoReturn(Itt.ErrorSet, ?Itt.Elem) {
            defer {
                if (@hasDecl(Itt, "deinit")) {
                    self.deinit();
                }
            }

            var ended: bool = false;
            var missing = index;

            // Skip all the previous elements
            while (missing > 0) {
                if (Itt.ErrorSet != null) {
                    ended = try self.next() == null;
                } else {
                    ended = self.next() == null;
                }

                missing -= 1;

                if (ended) return null;
            }

            if (Itt.ErrorSet != null) {
                return try self.next();
            } else {
                return self.next();
            }
        }
    };
}

test "itt first, last, positional empty iterator" {
    const IteratorUsize = TestIterator(usize, .{});

    var first = itt.from(IteratorUsize{}).first();
    var last = itt.from(IteratorUsize{}).last();

    try testing.expect(first == null);
    try testing.expect(last == null);

    var at0 = itt.from(IteratorUsize{}).at(0);
    var at1 = itt.from(IteratorUsize{}).at(1);

    try testing.expect(at0 == null);
    try testing.expect(at1 == null);
}

test "itt first, last, positional" {
    const IteratorUsize = TestIterator(usize, .{ 1, 2, 3, 4 });

    var first = itt.from(IteratorUsize{}).first();
    var last = itt.from(IteratorUsize{}).last();

    try testing.expect(first != null);
    try testing.expect(first.? == 1);
    try testing.expect(last != null);
    try testing.expect(last.? == 4);

    var at0 = itt.from(IteratorUsize{}).at(0);
    var at1 = itt.from(IteratorUsize{}).at(1);
    var at2 = itt.from(IteratorUsize{}).at(2);
    var at3 = itt.from(IteratorUsize{}).at(3);
    var at4 = itt.from(IteratorUsize{}).at(4);

    try testing.expect(at0 != null);
    try testing.expect(at0.? == 1);
    try testing.expect(at1 != null);
    try testing.expect(at1.? == 2);
    try testing.expect(at2 != null);
    try testing.expect(at2.? == 3);
    try testing.expect(at3 != null);
    try testing.expect(at3.? == 4);
    try testing.expect(at4 == null);
}
