const std = @import("std");
const IttGeneric = @import("../core.zig").IttGeneric;

pub fn MapOperator(comptime Itt: type) type {
    return struct {
        pub fn map(iter: Itt, transform: anytype) MapIterator(Itt, @TypeOf(transform), void) {
            return iter.mapCtx(transform, {});
        }

        pub fn mapField(iter: Itt, comptime field: anytype) MapIterator(Itt, fn (self: Itt.Elem) std.meta.fieldInfo(Itt.Elem, field).field_type, void) {
            comptime const FieldType = std.meta.fieldInfo(Itt.Elem, field).field_type;

            return iter.map(struct {
                pub fn function(self: Itt.Elem) FieldType {
                    return @field(self, @tagName(field));
                }
            }.function);
        }

        pub fn mapCtx(iter: Itt, transform: anytype, ctx: anytype) MapIterator(Itt, @TypeOf(transform), @TypeOf(ctx)) {
            return MapIterator(Itt, @TypeOf(transform), @TypeOf(ctx)){
                .source = iter,
                .transform = transform,
                .context = ctx,
            };
        }
    };
}

pub fn MapIterator(comptime Itt: type, comptime Transform: type, comptime Context: type) type {
    return struct {
        source: Itt,
        transform: Transform,
        context: Context,

        pub const Source = Itt;
        pub const Elem = @typeInfo(Transform).Fn.return_type.?;

        pub fn next(self: *@This()) ?Elem {
            if (self.source.next()) |value| {
                if (Context == void) {
                    return self.transform(value);
                } else {
                    return self.transform(self.context, value);
                }
            }

            return null;
        }

        pub usingnamespace IttGeneric(Itt.Operators, @This());
    };
}
