const std = @import("std");
const testing = std.testing;
const util = @import("test-util");
const TestStore = util.TestStore;

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
