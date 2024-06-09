const std = @import("std");
const testing = std.testing;
const ido = @import("ido");

pub const TestStore = struct {
    allocator: std.mem.Allocator = testing.allocator,
    tasks: []const ido.Task = &.{},

    pub fn init(tasks: []const ido.Task) TestStore {
        return .{ .tasks = tasks };
    }

    pub fn deinit(_: *TestStore) void {}

    pub fn taskStore(self: *TestStore) ido.TaskStore {
        return ido.TaskStore{
            .ptr = self,
            .vtable = &.{
                .save = save,
                .load = load,
            },
        };
    }

    fn save(ctx: *anyopaque, tasks: []const ido.Task) !void {
        var self: *TestStore = @ptrCast(@alignCast(ctx));
        self.tasks = tasks;
    }

    fn load(
        ctx: *anyopaque,
        allocator: std.mem.Allocator,
    ) !std.ArrayList(ido.Task) {
        const self: *TestStore = @ptrCast(@alignCast(ctx));
        var tasklist = std.ArrayList(ido.Task).init(allocator);
        try tasklist.appendSlice(self.tasks);
        return tasklist;
    }
};

pub fn expectTaskSliceEqual(
    expected: []const ido.Task,
    actual: []const ido.Task,
) !void {
    try testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |exp, act| {
        try expectTaskEqual(exp, act);
    }
}

pub fn expectTaskEqual(expected: ido.Task, actual: ido.Task) !void {
    try testing.expectEqualStrings(expected.name, actual.name);
    if (expected.description) |desc| {
        try testing.expectEqualStrings(desc, actual.description.?);
    } else {
        try testing.expectEqual(null, actual.description);
    }
    try testing.expectEqual(expected.done, actual.done);
}

pub fn checkTaskNotDone(task: ido.Task, name: []const u8, desc: ?[]const u8) !void {
    return checkTask(task, name, desc, false);
}

pub fn checkTaskDone(task: ido.Task, name: []const u8, desc: ?[]const u8) !void {
    return checkTask(task, name, desc, true);
}

fn checkTask(
    task: ido.Task,
    name: []const u8,
    description: ?[]const u8,
    done: bool,
) !void {
    try expectTaskEqual(.{
        .name = name,
        .description = description,
        .done = done,
    }, task);
}

test "TestStore empty store save empty" {
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{});

    try expectTaskSliceEqual(&.{}, test_store.tasks);
}

test "TestStore empty store save single task" {
    const task = .{ .name = "foo", .description = null, .done = false };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{task});

    try expectTaskSliceEqual(&.{task}, test_store.tasks);
}

test "TestStore empty store save multiple tasks" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{ task1, task2 });

    try expectTaskSliceEqual(&.{ task1, task2 }, test_store.tasks);
}

test "TestStore empty store load empty" {
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try expectTaskSliceEqual(test_store.tasks, tasklist.items);
}

test "TestStore save overwrite single task" {
    const task = .{ .name = "foo", .description = null, .done = false };
    const new_task = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{task});
    var store = test_store.taskStore();

    try store.save(&.{new_task});

    try expectTaskSliceEqual(&.{new_task}, test_store.tasks);
}

test "TestStore load single task" {
    const task = .{ .name = "foo", .description = null, .done = false };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{task});
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try expectTaskSliceEqual(&.{task}, tasklist.items);
}

test "TestStore load multiple tasks" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{ task1, task2 });
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try expectTaskSliceEqual(&.{ task1, task2 }, tasklist.items);
}

test "TestStore empty store save then load" {
    const task = .{ .name = "foo", .description = null, .done = false };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{task});
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try expectTaskSliceEqual(&.{task}, tasklist.items);
}

test "TestStore empty store save then load multiple" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{});
    var store = test_store.taskStore();

    try store.save(&.{ task1, task2 });
    const tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();

    try expectTaskSliceEqual(&.{ task1, task2 }, tasklist.items);
}

test "TestStore load then save" {
    const task1 = .{ .name = "foo", .description = null, .done = false };
    const task2 = .{ .name = "bar", .description = null, .done = true };
    var test_store = TestStore.init(&.{task1});
    var store = test_store.taskStore();

    var tasklist = try store.load(testing.allocator);
    defer tasklist.deinit();
    try tasklist.append(task2);
    try store.save(tasklist.items);

    try expectTaskSliceEqual(&.{ task1, task2 }, test_store.tasks);
}
