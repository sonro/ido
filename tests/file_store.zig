const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("util.zig");
const FileStore = ido.FileStore;
const Task = ido.Task;

test "init with nonexistent file" {
    const res = FileStore.init(allocator, "nonexistent.ido");
    try testing.expectError(error.FileNotFound, res);
}

test "init with empty file" {
    const contents = "";
    const tester = FileStoreTester(testInit, contents){};
    try tester.call(.{contents});
}

test "init with non-empty file" {
    const contents = "hello world";
    const tester = FileStoreTester(testInit, contents){};
    try tester.call(.{contents});
}

fn testInit(store: FileStore, expected: []const u8) !void {
    try testing.expectEqualStrings(expected, store.contents);
}

fn FileStoreTester(test_fn: anytype, contents: []const u8) type {
    return struct {
        contents: []const u8 = contents,
        const Self = @This();

        pub fn call(self: Self, args: anytype) !void {
            var file = try util.TestFile.init(self.contents);
            defer file.deinit();
            const store = try FileStore.init(allocator, file.path);
            defer store.deinit();
            try testing.expectEqualStrings(file.path, store.path);
            try @call(.auto, test_fn, .{store} ++ args);
        }
    };
}
