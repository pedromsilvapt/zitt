const std = @import("std");
const testing = std.testing;

pub fn ReturnType(comptime Itt: type) type {
    const next_decl = @typeInfo(@TypeOf(@field(Itt, "next")));

    if (comptime next_decl != .Fn) {
        @compileError("Iterator 'next' declaration is not a function");
    }

    return next_decl.Fn.return_type.?;
}

pub fn Elem(comptime Itt: type) type {
    comptime const return_type = ReturnType(Itt);

    const return_info = @typeInfo(return_type);

    if (return_info == .ErrorUnion) {
        return std.meta.Child(return_info.ErrorUnion.payload);
    } else {
        return std.meta.Child(return_type);
    }
}

pub fn AutoReturn(comptime ErrorSetType: ?type, comptime ElemType: type) type {
    if (ErrorSetType == null or @typeInfo(ErrorSetType.?).ErrorSet.len == 0) {
        return ElemType;
    } else {
        return ErrorSetType!ElemType;
    }
}

pub fn ErrorSet(comptime Itt: type) ?type {
    comptime const return_type = ReturnType(Itt);

    const return_info = @typeInfo(return_type);

    if (return_info == .ErrorUnion) {
        const error_set = return_info.ErrorUnion.error_set;

        if (@typeInfo(error_set).ErrorSet.len > 0) {
            return error_set;
        } else {
            return null;
        }
    } else {
        return null;
    }
}

const UsizeIterator = struct {
    pub fn next() ?usize {
        return null;
    }
};

const I32Iterator = struct {
    pub fn next() ?i32 {
        return null;
    }
};

const MaybeI32Iterator = struct {
    pub fn next() error{OutOfMemory}!?i32 {
        return null;
    }
};
test "Elem" {
    try testing.expect(Elem(UsizeIterator) == usize);
    try testing.expect(Elem(I32Iterator) == i32);
    try testing.expect(Elem(MaybeI32Iterator) == i32);
    try testing.expect(Elem(I32Iterator) != usize);
}
