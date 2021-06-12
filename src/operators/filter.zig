const IttGeneric = @import("../core.zig").IttGeneric;
const meta = @import("../meta.zig");

pub fn FilterOperator(comptime Itt: type) type {
    return struct {
        pub fn filter(iter: Itt, predicate: anytype) FilterIterator(Itt, @TypeOf(predicate), void) {
            return iter.filterCtx(predicate, {});
        }

        pub fn filterCtx(iter: Itt, predicate: anytype, ctx: anytype) FilterIterator(Itt, @TypeOf(predicate), @TypeOf(ctx)) {
            return FilterIterator(Itt, @TypeOf(predicate), @TypeOf(ctx)){
                .source = iter,
                .predicate = predicate,
                .context = ctx,
            };
        }
    };
}

pub fn FilterIterator(comptime Itt: type, comptime Predicate: type, comptime Context: type) type {
    return struct {
        source: Itt,
        predicate: Predicate,
        context: Context,

        pub const Source = Itt;
        pub const Elem = Itt.Elem;

        pub fn next(self: *@This()) ?Elem {
            while (true) {
                // Respect source iterators that may fail
                var value_optional = if (Itt.ErrorSet != null)
                    try self.source.next()
                else
                    self.source.next();

                if (value_optional) |value| {
                    var pass: bool = false;
                    if (Context == void) {
                        pass = self.predicate(value);
                    } else {
                        pass = self.predicate(context, value);
                    }

                    if (pass) {
                        return value;
                    }
                } else {
                    break;
                }
            }

            return null;
        }

        pub usingnamespace IttGeneric(Itt.Operators, @This());
    };
}
