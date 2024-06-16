const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");
const Task = ido.Task;
const Manager = ido.Manager;
const FOUR_TODOS = util.FOUR_TODOS;
const FOUR_DONES = util.FOUR_DONES;
const FOUR_MIXED = util.FOUR_MIXED;
const ONE_TODO = util.ONE_TODO;
const ONE_DONE = util.ONE_DONE;
const EMPTY_TASKS = util.EMPTY_TASKS;

test "all tasks empty store" {
    var tester = ManagerTester(testAllTasks){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    try tester.call(.{EMPTY_TASKS});
}

test "all tasks non empty store" {
    var tester = ManagerTester(testAllTasks){
        .tasks = FOUR_TODOS,
        .expected_saves = 0,
    };
    try tester.call(.{FOUR_TODOS});
}

fn testAllTasks(manager: *Manager, expected: []const Task) !void {
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "save empty over empty" {
    try checkSave(EMPTY_TASKS, EMPTY_TASKS);
}

test "save empty over full" {
    try checkSave(FOUR_MIXED, EMPTY_TASKS);
}

test "save full over empty" {
    try checkSave(EMPTY_TASKS, FOUR_MIXED);
}

fn checkSave(existing: []const Task, new: []const Task) !void {
    var tester = ManagerTester(testSave){
        .tasks = existing,
        .expected_saves = 1,
        .expected_manual_saves = 1,
    };
    try tester.call(.{new});
}

fn testSave(manager: *Manager, expected: []const Task) !void {
    manager.tasks.clearRetainingCapacity();
    try manager.tasks.appendSlice(expected);
    try manager.save();
    const actual = try manager.store.load(allocator);
    defer actual.deinit();
    try util.expectTaskSliceEqual(expected, actual.items);
}

test "reload empty tasks" {
    try checkReload(EMPTY_TASKS);
}

test "reload multiple tasks" {
    try checkReload(FOUR_MIXED);
}

fn checkReload(expected: []const Task) !void {
    var tester = ManagerTester(testReload){
        .tasks = EMPTY_TASKS,
        .expected_saves = 1,
        .expected_manual_saves = 1,
    };
    try tester.call(.{expected});
}

fn testReload(manager: *Manager, expected: []const Task) !void {
    // modify manager's tasklist
    try manager.tasks.append(.{ .name = "testLoadTask" });
    // ensure the manager's store has what we expect
    try manager.store.save(expected);

    try manager.reload();
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "add task empty store" {
    try checkAddTask(.{
        .stored = EMPTY_TASKS,
        .task = ONE_TODO[0],
        .expected = EMPTY_TASKS ++ ONE_TODO,
    });
}

test "add task non empty store" {
    const task = Task{ .name = "testAddTask" };
    try checkAddTask(.{
        .stored = FOUR_TODOS,
        .task = task,
        .expected = FOUR_TODOS ++ &[_]Task{task},
    });
}

fn checkAddTask(args: anytype) !void {
    var tester = ManagerTester(testAddTask){
        .tasks = args.stored,
        .expected_saves = 1,
    };
    try tester.call(.{ args.task, args.expected });
}

fn testAddTask(manager: *Manager, task: Task, expected: []const Task) !void {
    const index = try manager.addTask(task);
    const actual = manager.getTask(index);
    try testing.expect(actual != null);
    try util.expectTaskEqual(task, actual.?);
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "get one task with multiple task store" {
    var tester = ManagerTester(testGetOne){
        .tasks = FOUR_TODOS,
        .expected_saves = 0,
    };
    const index = 1;
    try tester.call(.{ index, FOUR_TODOS[index] });
}

test "get one task with single task store" {
    var tester = ManagerTester(testGetOne){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    const index = 0;
    try tester.call(.{ index, ONE_TODO[index] });
}

test "get one with invalid index" {
    var tester = ManagerTester(testGetOne){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    const index = 1;
    try tester.call(.{ index, null });
}

test "get one task with empty store" {
    var tester = ManagerTester(testGetOne){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    const index = 0;
    try tester.call(.{ index, null });
}

fn testGetOne(manager: *Manager, index: usize, expected: ?Task) !void {
    const actual = manager.getTask(index);
    if (expected == null) {
        try testing.expectEqual(null, actual);
    } else {
        try util.expectTaskEqual(expected.?, actual.?);
    }
}

test "mark done one task" {
    var tester = ManagerTester(testMarkDone){
        .tasks = ONE_TODO,
        .expected_saves = 1,
    };
    const index = 0;
    try tester.call(.{index});
}

test "mark done full store of dones" {
    var tester = ManagerTester(testMarkDone){
        .tasks = FOUR_DONES,
        .expected_saves = 1,
    };
    const index = 3;
    try tester.call(.{index});
}

test "mark done full store of todos" {
    var tester = ManagerTester(testMarkDone){
        .tasks = FOUR_TODOS,
        .expected_saves = 1,
    };
    const index = 3;
    try tester.call(.{index});
}

test "mark done invalid index" {
    var tester = ManagerTester(testIndexError){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    const index = 1;
    try tester.call(.{ Manager.markDone, index });
}

test "mark done empty store" {
    var tester = ManagerTester(testIndexError){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    const index = 0;
    try tester.call(.{ Manager.markDone, index });
}

fn testMarkDone(manager: *Manager, index: usize) !void {
    const actual = try manager.markDone(index);
    try testMark(manager, index, true, actual);
}

test "unmark done one task" {
    var tester = ManagerTester(testUnmarkDone){
        .tasks = ONE_DONE,
        .expected_saves = 1,
    };
    const index = 0;
    try tester.call(.{index});
}

test "unmark done full store of todos" {
    var tester = ManagerTester(testUnmarkDone){
        .tasks = FOUR_TODOS,
        .expected_saves = 1,
    };
    const index = 2;
    try tester.call(.{index});
}

test "unmark done full store of dones" {
    var tester = ManagerTester(testUnmarkDone){
        .tasks = FOUR_DONES,
        .expected_saves = 1,
    };
    const index = 3;
    try tester.call(.{index});
}

test "unmark done invalid index" {
    var tester = ManagerTester(testIndexError){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    const index = 1;
    try tester.call(.{ Manager.unmarkDone, index });
}

test "unmark done empty store" {
    var tester = ManagerTester(testIndexError){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    const index = 0;
    try tester.call(.{ Manager.unmarkDone, index });
}

fn testUnmarkDone(manager: *Manager, index: usize) !void {
    const actual = try manager.unmarkDone(index);
    try testMark(manager, index, false, actual);
}

test "delete one task" {
    var tester = ManagerTester(testDelete){
        .tasks = ONE_TODO,
        .expected_saves = 1,
    };
    const index = 0;
    try tester.call(.{ EMPTY_TASKS, index });
}

test "delete invalid index" {
    var tester = ManagerTester(testIndexError){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    const index = 1;
    try tester.call(.{ Manager.delete, index });
}

test "delete empty store" {
    var tester = ManagerTester(testIndexError){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    const index = 0;
    try tester.call(.{ Manager.delete, index });
}

test "delete middle task and preserve order" {
    const expected = &.{
        FOUR_TODOS[0],
        FOUR_TODOS[2],
        FOUR_TODOS[3],
    };
    var tester = ManagerTester(testDelete){
        .tasks = FOUR_TODOS,
        .expected_saves = 1,
    };
    const index = 1;
    try tester.call(.{ expected, index });
}

fn testDelete(manager: *Manager, expected: []const Task, index: usize) !void {
    try manager.delete(index);
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "set task first" {
    const expected = &.{
        FOUR_TODOS[1],
        FOUR_TODOS[0],
        FOUR_TODOS[2],
        FOUR_TODOS[3],
    };
    var tester = ManagerTester(testSetFirst){
        .tasks = FOUR_TODOS,
        .expected_saves = 1,
    };
    const index = 1;
    try tester.call(.{ expected, index });
}

test "set single task first" {
    var tester = ManagerTester(testSetFirst){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    const index = 0;
    try tester.call(.{ ONE_TODO, index });
}

test "set first invalid index" {
    var tester = ManagerTester(testIndexError){
        .tasks = ONE_TODO,
        .expected_saves = 0,
    };
    try tester.call(.{ Manager.setFirst, 1 });
}

test "set first empty store" {
    var tester = ManagerTester(testIndexError){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    try tester.call(.{ Manager.setFirst, 0 });
}

test "set first from end task and preserve order" {
    const expected = &.{
        FOUR_TODOS[3],
        FOUR_TODOS[0],
        FOUR_TODOS[1],
        FOUR_TODOS[2],
    };
    var tester = ManagerTester(testSetFirst){
        .tasks = FOUR_TODOS,
        .expected_saves = 1,
    };
    const index = 3;
    try tester.call(.{ expected, index });
}

fn testSetFirst(manager: *Manager, expected: []const Task, index: usize) !void {
    try manager.setFirst(index);
    const actual = manager.allTasks();
    try util.expectTaskSliceEqual(expected, actual);
}

test "delete all done empty store" {
    var tester = ManagerTester(testDeleteAllDone){
        .tasks = EMPTY_TASKS,
        .expected_saves = 0,
    };
    try tester.call(.{});
}

test "delete all done with only dones" {
    var tester = ManagerTester(testDeleteAllDone){
        .tasks = FOUR_DONES,
        .expected_saves = 1,
    };
    try tester.call(.{});
}

test "delete all done with only todos" {
    var tester = ManagerTester(testDeleteAllDone){
        .tasks = FOUR_TODOS,
        .expected_saves = 0,
    };
    try tester.call(.{});
}

test "delete all done with todos and dones" {
    var tester = ManagerTester(testDeleteAllDone){
        .tasks = FOUR_MIXED,
        .expected_saves = 1,
    };
    try tester.call(.{});
}

fn testDeleteAllDone(manager: *Manager) !void {
    const original_tasks = manager.allTasks();
    const done_count = countDone(original_tasks);
    const expected_tasks_len = original_tasks.len - done_count;

    try manager.deleteAllDone();
    const actual_tasks = manager.allTasks();

    try testing.expectEqual(expected_tasks_len, actual_tasks.len);
    try testing.expectEqual(0, countDone(actual_tasks));
}

fn countDone(tasks: []const Task) usize {
    var count: usize = 0;
    for (tasks) |task| {
        if (task.done) count += 1;
    }
    return count;
}

fn testIndexError(manager: *Manager, method: anytype, index: usize) !void {
    try testing.expectError(
        error.OutOfRange,
        @call(.auto, method, .{ manager, index }),
    );
}

fn testMark(manager: *Manager, index: usize, expected: bool, actual: Task) !void {
    const got = manager.getTask(index);
    try testing.expect(got != null);
    try util.expectTaskEqual(actual, got.?);
    try testing.expectEqual(expected, actual.done);
}

/// Create a testing environment for a `Manager`.
fn ManagerTester(test_fn: anytype) type {
    return struct {
        /// Tasks to put in the manager's store.
        tasks: []const Task,
        /// Expected number of writes to the store.
        expected_saves: usize,
        expected_manual_saves: usize = 0,
        const Self = @This();

        /// Test the function on both an
        /// autos and manual saving `Manager`.
        pub fn call(self: *Self, args: anytype) !void {
            try self.callAuto(args);
            try self.callManual(args);
        }

        pub fn callAuto(self: *Self, args: anytype) !void {
            var store = util.TestStore.init(self.tasks);
            var manager = try Manager.init(allocator, store.taskStore());
            defer manager.deinit();
            try @call(.auto, test_fn, .{&manager} ++ args);
            try testing.expectEqual(self.expected_saves, store.saved);
        }

        pub fn callManual(self: *Self, args: anytype) !void {
            var store = util.TestStore.init(self.tasks);
            var manager = try Manager.initManualSave(allocator, store.taskStore());
            defer manager.deinit();
            try @call(.auto, test_fn, .{&manager} ++ args);
            try testing.expectEqual(self.expected_manual_saves, store.saved);
        }
    };
}
