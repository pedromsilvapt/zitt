pub fn SliceIterator(comptime Elem: type) type {
    return struct {
        source: []const Elem,
        cursor: usize = 0,

        pub fn init(source: []const Elem) @This() {
            return .{
                .source = source,
            };
        }

        pub fn next(self: *@This()) ?Elem {
            if (self.cursor < self.source.len) {
                defer self.cursor += 1;

                return self.source[self.cursor];
            }

            return null;
        }
    };
}
