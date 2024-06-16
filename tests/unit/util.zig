const std = @import("std");
const testing = std.testing;
const util = @import("test-util");
const TestStore = util.TestStore;
const Task = @import("ido").Task;
const allocator = testing.allocator;
const FOUR_TODOS = util.FOUR_TODOS;
const FOUR_DONES = util.FOUR_DONES;
const FOUR_MIXED = util.FOUR_MIXED;
const ONE_TODO = util.ONE_TODO;
const ONE_DONE = util.ONE_DONE;
const EMPTY_TASKS = util.EMPTY_TASKS;

test "TestStore empty store save empty" {
    var test_store = TestStore.init(&.{});

    try test_store.save(&.{});

    try util.expectTaskSliceEqual(&.{}, test_store.tasks);
}

test "TestStore empty store save single task" {
    const task = .{ .name = "foo", .description = null, .done = false };
    var test_store = TestStore.init(&.{});

    try test_store.save(&.{task});

    try util.expectTaskSliceEqual(&.{task}, test_store.tasks);
}

test "TestStore empty store save multiple tasks" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{ task1, task2 });

    try util.expectTaskSliceEqual(&.{ task1, task2 }, test_store.tasks);
}

test "TestStore empty store load empty" {
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try util.expectTaskSliceEqual(test_store.tasks, tasklist.items);
}

test "TestStore save overwrite single task" {
    const task = .{ .name = "foo", .description = null, .done = false };
    const new_task = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{task});
    var store = test_store.taskStore();

    try store.save(&.{new_task});

    try util.expectTaskSliceEqual(&.{new_task}, test_store.tasks);
}

test "TestStore load single task" {
    const task = .{ .name = "foo", .description = null, .done = false };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{task});
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try util.expectTaskSliceEqual(&.{task}, tasklist.items);
}

test "TestStore load multiple tasks" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{ task1, task2 });
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try util.expectTaskSliceEqual(&.{ task1, task2 }, tasklist.items);
}

test "TestStore empty store save then load" {
    const task = .{ .name = "foo", .description = null, .done = false };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{task});
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try util.expectTaskSliceEqual(&.{task}, tasklist.items);
}

test "TestStore empty store save then load multiple" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{ task1, task2 });
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try util.expectTaskSliceEqual(&.{ task1, task2 }, tasklist.items);
}

test "TestStore load then save" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{task1});

    var tasklist = try test_store.load(testing.allocator);
    defer tasklist.deinit();
    try tasklist.append(task2);
    try test_store.save(tasklist.items);

    try util.expectTaskSliceEqual(&.{ task1, task2 }, test_store.tasks);
}

test "TestStore emtpy loadInto empty" {
    try testLoadInto(.{});
}

test "TestStore one task loadInto empty" {
    try testLoadInto(.{ .stored = ONE_TODO, .expected = ONE_TODO });
}

test "TestStore one task loadInto one task" {
    try testLoadInto(.{
        .listed = ONE_TODO,
        .stored = ONE_DONE,
        .expected = &.{ ONE_TODO[0], ONE_DONE[0] },
    });
}

test "TestStore multi task loadInto multi task" {
    var expected: [8]Task = undefined;
    inline for (0..4) |i| {
        expected[i] = FOUR_TODOS[i];
        expected[i + 4] = FOUR_DONES[i];
    }
    try testLoadInto(.{
        .listed = FOUR_TODOS,
        .stored = FOUR_DONES,
        .expected = &expected,
    });
}

const LoadIntoConfig = struct {
    listed: []const Task = EMPTY_TASKS,
    stored: []const Task = EMPTY_TASKS,
    expected: []const Task = EMPTY_TASKS,
};

fn testLoadInto(args: LoadIntoConfig) !void {
    var tasklist = try std.ArrayList(Task).initCapacity(allocator, args.listed.len);
    if (args.listed.len > 0) {
        try tasklist.appendSlice(args.listed);
    }
    defer tasklist.deinit();

    var test_store = TestStore.init(args.stored);
    const store = test_store.taskStore();
    try store.loadInto(&tasklist);

    try util.expectTaskSliceEqual(args.expected, tasklist.items);
}
