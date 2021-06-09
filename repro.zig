pub const Foo = struct {
    pub fn bar() void {}
};
pub const Foo2 = struct {
    usingnamespace struct {
        pub fn bar() void {}
    };
};
pub const Foo3 = struct {
    usingnamespace struct {
        pub usingnamespace struct {
            pub fn bar() void {}
        };
    };
};

test "Foo.bar" {
    // Works
    Foo.bar();
    // Works
    Foo2.bar();
    // error: container 'Foo3' has no member called 'bar'
    Foo3.bar();
}
