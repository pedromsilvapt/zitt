pub fn ArrayIterator(comptime Elem: type, comptime len: comptime_int) type {
    return struct {
        source: [len]Elem,
        cursor: usize = 0,

        pub fn init(source: [len]Elem) @This() {
            return .{
                .source = source,
            };
        }

        pub fn next(self: *@This()) ?Elem {
            if (self.cursor < len) {
                defer self.cursor += 1;

                return self.source[self.cursor];
            }

            return null;
        }
    };
}
