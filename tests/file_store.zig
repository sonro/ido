const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("util.zig");
const FileStore = ido.FileStore;
const Task = ido.Task;
const TestFormat = util.TestFormat;

const EMPTY_TASKS = util.EMPTY_TASKS;
const ONE_TODO = util.ONE_TODO;
const FOUR_MIXED = util.FOUR_MIXED;

const Store = FileStore(TestFormat);

test "init with empty file" {
    const contents = "";
    const tester = FileStoreTester(testInit){ .contents = contents };
    try tester.call(.{});
}

test "init with non-empty file" {
    const contents = "hello world";
    const tester = FileStoreTester(testInit){ .contents = contents };
    try tester.call(.{});
}

fn testInit(_: *Store) !void {}

test "load empty file" {
    const contents = "";
    const tester = FileStoreTester(testLoad){ .contents = contents };
    try tester.call(.{EMPTY_TASKS});
}

test "load invalid file" {
    const contents = "hello world";
    const tester = FileStoreTester(testInvalidFormatError){ .contents = contents };
    try tester.call(.{});
}

test "load one task" {
    const contents = try generateContents(ONE_TODO);
    defer allocator.free(contents);
    const tester = FileStoreTester(testLoad){ .contents = contents };
    try tester.call(.{ONE_TODO});
}

test "load multiple tasks" {
    const contents = try generateContents(FOUR_MIXED);
    defer allocator.free(contents);
    const tester = FileStoreTester(testLoad){ .contents = contents };
    try tester.call(.{FOUR_MIXED});
}

fn testLoad(store: *Store, expected: []const Task) !void {
    const actual = try store.load(allocator);
    defer actual.deinit();
    try util.expectTaskSliceEqual(expected, actual.items);
}

fn testInvalidFormatError(store: *Store) !void {
    try testing.expectError(error.InvalidFormat, store.load(allocator));
}

fn generateContents(tasks: []const Task) ![]const u8 {
    var buf = std.ArrayList(u8).init(allocator);
    errdefer buf.deinit();
    try TestFormat.serializeTaskList(tasks, buf.writer());
    return buf.toOwnedSlice();
}

fn FileStoreTester(test_fn: anytype) type {
    return struct {
        contents: []const u8,
        const Self = @This();

        pub fn call(self: Self, args: anytype) !void {
            var file = try util.TestFile.init(self.contents);
            defer file.deinit();
            var store = Store.init(allocator, file.path);
            defer store.deinit();
            try testing.expectEqualStrings(file.path, store.path);
            try @call(.auto, test_fn, .{&store} ++ args);
        }
    };
}
