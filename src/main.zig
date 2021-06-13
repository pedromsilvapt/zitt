const std = @import("std");
const testing = std.testing;
const root = @import("root");

pub const IttBase = @import("./core.zig").IttBase;
pub const IttGeneric = @import("./core.zig").IttGeneric;
pub const IttFactory = @import("./core.zig").IttFactory;

// Base Generators
pub fn IttBaseGenerators(comptime Operators: anytype) type {
    return struct {
        pub usingnamespace @import("./generators/from.zig").FromGenerator(Operators);
        pub usingnamespace @import("./generators/single.zig").SingleGenerator(Operators);
        pub usingnamespace @import("./generators/fail.zig").FailGenerator(Operators);
        pub usingnamespace @import("./generators/range.zig").RangeGenerator(Operators);

        pub usingnamespace if (@hasDecl(root, "IttCustomGenerators"))
            root.IttCustomGenerators(Itt)
        else
            struct {};
    };
}

pub fn IttBaseOperators(comptime Itt: type) type {
    return struct {
        pub usingnamespace @import("./operators/map.zig").MapOperator(Itt);
        pub usingnamespace @import("./operators/filter.zig").FilterOperator(Itt);

        pub usingnamespace if (@hasDecl(root, "IttCustomOperators"))
            root.IttCustomOperators(Itt)
        else
            struct {};
    };
}

pub usingnamespace IttFactory(IttBaseOperators, IttBaseGenerators);
