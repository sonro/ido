const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");
const FileStore = ido.FileStore;
const Task = ido.Task;
const TestFormat = util.TestFormat;

const EMPTY_TASKS = util.EMPTY_TASKS;
const ONE_TODO = util.ONE_TODO;
const FOUR_MIXED = util.FOUR_MIXED;

const Store = FileStore(TestFormat);

test "init with empty file" {
    try checkInit("");
}

test "init with non-empty file" {
    try checkInit("hello world");
}

fn checkInit(contents: []const u8) !void {
    const tester = FileStoreTester(testInit){ .contents = contents };
    try tester.call(.{});
}

fn testInit(_: *Store) !void {}

test "load empty file" {
    try checkLoad(EMPTY_TASKS);
}

test "load one task" {
    try checkLoad(ONE_TODO);
}

test "load multiple tasks" {
    try checkLoad(FOUR_MIXED);
}

test "load invalid file" {
    const contents = "hello world";
    const tester = FileStoreTester(testInvalidFormatError){ .contents = contents };
    try tester.call(.{});
}

fn checkLoad(tasks: []const Task) !void {
    try checkTestFn(testLoad, tasks, tasks);
}

fn testLoad(store: *Store, expected: []const Task) !void {
    const actual = try store.load(allocator);
    defer actual.deinit();
    try util.expectTaskSliceEqual(expected, actual.items);
}

test "load into empty file" {
    try checkLoadInto(EMPTY_TASKS);
}

test "load into one task" {
    try checkLoadInto(ONE_TODO);
}

test "load into multiple tasks" {
    try checkLoadInto(FOUR_MIXED);
}

fn checkLoadInto(tasks: []const Task) !void {
    try checkTestFn(testLoadInto, tasks, tasks);
}

fn testLoadInto(store: *Store, expected: []const Task) !void {
    var tasklist = std.ArrayList(Task).init(allocator);
    defer tasklist.deinit();
    try store.loadInto(&tasklist);
    try util.expectTaskSliceEqual(expected, tasklist.items);
}

test "save no tasks over no tasks" {
    try checkSave(EMPTY_TASKS, EMPTY_TASKS);
}

test "save no tasks over one task" {
    try checkSave(ONE_TODO, EMPTY_TASKS);
}

test "save one task over no tasks" {
    try checkSave(EMPTY_TASKS, ONE_TODO);
}

test "save multiple tasks over one task" {
    try checkSave(ONE_TODO, FOUR_MIXED);
}

fn checkSave(stored: []const Task, save: []const Task) !void {
    const contents = try generateContents(stored);
    defer allocator.free(contents);

    const expected = try generateContents(save);
    defer allocator.free(expected);

    const tester = FileStoreTester(testSaveThenLoad){ .contents = contents };
    try tester.callAndTestFile(.{save}, expected);
}

fn testSave(store: *Store, tasks: []const Task) !void {
    try store.save(tasks);
}

test "save then load no tasks" {
    try checkSaveThenLoad(EMPTY_TASKS, EMPTY_TASKS);
}

test "save then load one task over no tasks" {
    try checkSaveThenLoad(EMPTY_TASKS, ONE_TODO);
}

test "save then load multiple tasks over one task" {
    try checkSaveThenLoad(ONE_TODO, FOUR_MIXED);
}

fn checkSaveThenLoad(stored: []const Task, save: []const Task) !void {
    try checkTestFn(testSaveThenLoad, stored, save);
}

fn testSaveThenLoad(store: *Store, tasks: []const Task) !void {
    try store.save(tasks);
    const actual = try store.load(allocator);
    defer actual.deinit();
    try util.expectTaskSliceEqual(tasks, actual.items);
}

test "interface save then load" {
    try checkTestFn(testInterfaceSaveThenLoad, EMPTY_TASKS, FOUR_MIXED);
}

fn testInterfaceSaveThenLoad(store: *Store, tasks: []const Task) !void {
    const taskStore = store.taskStore();
    try taskStore.save(tasks);
    const actual = try taskStore.load(allocator);
    defer actual.deinit();
    try util.expectTaskSliceEqual(tasks, actual.items);
}

test "interface save then load into" {
    try checkTestFn(testInterfaceSaveThenLoadInto, FOUR_MIXED[0..2], FOUR_MIXED[2..]);
}

fn testInterfaceSaveThenLoadInto(store: *Store, tasks: []const Task) !void {
    const taskStore = store.taskStore();
    try taskStore.save(tasks);

    var tasklist = std.ArrayList(Task).init(allocator);
    defer tasklist.deinit();

    try taskStore.loadInto(&tasklist);
    try util.expectTaskSliceEqual(tasks, tasklist.items);
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

fn checkTestFn(test_fn: anytype, stored: []const Task, tasks: []const Task) !void {
    const contents = try generateContents(stored);
    defer allocator.free(contents);
    const tester = FileStoreTester(test_fn){ .contents = contents };
    try tester.call(.{tasks});
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
