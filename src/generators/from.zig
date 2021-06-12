const IttBase = @import("../core.zig").IttBase;

pub fn FromGenerator(comptime Operators: anytype) type {
    return struct {
        pub fn from(src: anytype) IttBase(Operators, InferredIteratorType(@TypeOf(src))) {
            var iter: InferredIteratorType(@TypeOf(src)) = undefined;

            const type_info = @typeInfo(@TypeOf(src));

            if (type_info == .Array) {
                iter = ArrayIterator(type_info.Array.child, type_info.Array.len).init(src);
            } else if (type_info == .Pointer and type_info.Pointer.size == .Slice) {
                iter = SliceIterator(type_info.Pointer.child).init(src);
            } else {
                iter = src;
            }

            return IttBase(Operators, InferredIteratorType(@TypeOf(src))).init(iter);
        }
    };
}

/// Infers the iterator type for a given value type.
/// If given an array or slice, creates an iterator type for them sepcifically
/// Otherwise assumes the given value is a structure with a `.next()` method that behaves
/// like an iterator
pub fn InferredIteratorType(comptime Src: type) type {
    const type_info = @typeInfo(Src);

    if (type_info == .Array) {
        return ArrayIterator(type_info.Array.child, type_info.Array.len);
    } else if (type_info == .Pointer and type_info.Pointer.size == .Slice) {
        return SliceIterator(type_info.Pointer.child);
    } else {
        return Src;
    }
}

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
