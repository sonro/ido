const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("../util/util.zig");
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

test "save no tasks over no tasks" {
    const contents = try generateContents(EMPTY_TASKS);
    defer allocator.free(contents);
    const tester = FileStoreTester(testSave){ .contents = contents };
    try tester.callAndTestFile(.{EMPTY_TASKS}, contents);
}

test "save no tasks over one task" {
    const contents = try generateContents(ONE_TODO);
    const expected = try generateContents(EMPTY_TASKS);
    defer allocator.free(contents);
    defer allocator.free(expected);
    const tester = FileStoreTester(testSave){ .contents = contents };
    try tester.callAndTestFile(.{EMPTY_TASKS}, expected);
}

test "save one task over no tasks" {
    const contents = try generateContents(EMPTY_TASKS);
    const expected = try generateContents(ONE_TODO);
    defer allocator.free(contents);
    defer allocator.free(expected);
    const tester = FileStoreTester(testSave){ .contents = contents };
    try tester.callAndTestFile(.{ONE_TODO}, expected);
}

test "save multiple tasks over one task" {
    const contents = try generateContents(ONE_TODO);
    const expected = try generateContents(FOUR_MIXED);
    defer allocator.free(contents);
    defer allocator.free(expected);
    const tester = FileStoreTester(testSave){ .contents = contents };
    try tester.callAndTestFile(.{FOUR_MIXED}, expected);
}

fn testSave(store: *Store, tasks: []const Task) !void {
    try store.save(tasks);
}

test "save then load no tasks" {
    const contents = try generateContents(EMPTY_TASKS);
    defer allocator.free(contents);
    const tester = FileStoreTester(testSaveThenLoad){ .contents = contents };
    try tester.call(.{EMPTY_TASKS});
}

test "save then load one task over no tasks" {
    const contents = try generateContents(EMPTY_TASKS);
    defer allocator.free(contents);
    const tester = FileStoreTester(testSaveThenLoad){ .contents = contents };
    try tester.call(.{ONE_TODO});
}

test "save then load multiple tasks over one task" {
    const contents = try generateContents(ONE_TODO);
    defer allocator.free(contents);
    const tester = FileStoreTester(testSaveThenLoad){ .contents = contents };
    try tester.call(.{FOUR_MIXED});
}

fn testSaveThenLoad(store: *Store, expected: []const Task) !void {
    try store.save(expected);
    const actual = try store.load(allocator);
    defer actual.deinit();
    try util.expectTaskSliceEqual(expected, actual.items);
}

test "interface save then load" {
    const contents = try generateContents(FOUR_MIXED);
    defer allocator.free(contents);
    const tester = FileStoreTester(testInterfaceSaveThenLoad){ .contents = contents };
    try tester.call(.{FOUR_MIXED});
}

fn testInterfaceSaveThenLoad(store: *Store, expected: []const Task) !void {
    const taskStore = store.taskStore();
    try taskStore.save(expected);
    const actual = try taskStore.load(allocator);
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
            try callFile(args, file.path);
        }

        pub fn callAndTestFile(self: Self, args: anytype, expected: []const u8) !void {
            var file = try util.TestFile.init(self.contents);
            defer file.deinit();
            try callFile(args, file.path);

            const actual = try std.fs.cwd().readFileAlloc(
                allocator,
                file.path,
                std.math.maxInt(usize),
            );
            defer allocator.free(actual);
            try testing.expectEqualStrings(expected, actual);
        }

        fn callFile(args: anytype, path: []const u8) !void {
            var store = Store.init(allocator, path);
            defer store.deinit();
            try testing.expectEqualStrings(path, store.path);
            try @call(.auto, test_fn, .{&store} ++ args);
        }
    };
}
