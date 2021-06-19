const std = @import("std");
const meta = @import("std").meta;

pub fn FieldExpr(comptime T: type, comptime field: meta.FieldEnum(T)) type {
    return struct {
        a: i32 = 2,

        pub const ReturnType = meta.fieldInfo(T, field).field_type;

        pub fn apply(obj: T, self: @This()) ReturnType {
            return @field(obj, @tagName(field));
        }
    };
}

pub fn MethodExpr(comptime T: type, comptime method: DeclEnum(T), comptime Args: type) type {
    return struct {
        args: Args,

        pub const ReturnType = meta.declarationInfo(T, @tagName(method)).data.Fn.return_type;

        pub fn apply(obj: T, self: @This()) ReturnType {
            return @call(.{}, @field(obj, @tagName(method)), self.args);
        }
    };
}

pub fn DeclEnum(comptime T: type) type {
    const declInfos = meta.declarations(T);
    var enumFields: [declInfos.len]std.builtin.TypeInfo.EnumField = undefined;
    var decls = [_]std.builtin.TypeInfo.Declaration{};

    inline for (declInfos) |decl, i| {
        enumFields[i] = .{
            .name = decl.name,
            .value = i,
        };
    }

    return @Type(.{
        .Enum = .{
            .layout = .Auto,
            .tag_type = std.math.IntFittingRange(0, declInfos.len - 1),
            .fields = &enumFields,
            .decls = &decls,
            .is_exhaustive = true,
        },
    });
}
