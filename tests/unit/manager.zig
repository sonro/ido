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
        .auto_saves = 0,
    };
    try tester.call(.{EMPTY_TASKS});
}

test "all tasks non empty store" {
    var tester = ManagerTester(testAllTasks){
        .tasks = FOUR_TODOS,
        .auto_saves = 0,
    };
    try tester.call(.{FOUR_TODOS});
}

fn testAllTasks(manager: *Manager, expected: []const Task) !void {
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "save empty over empty" {
    try checkSave(.{ .stored = EMPTY_TASKS, .expected = EMPTY_TASKS });
}

test "save empty over full" {
    try checkSave(.{ .stored = FOUR_MIXED, .expected = EMPTY_TASKS });
}

test "save full over empty" {
    try checkSave(.{ .stored = EMPTY_TASKS, .expected = FOUR_MIXED });
}

fn checkSave(opts: CheckOpts) !void {
    var op = opts;
    op.manual_saves = 1;
    try checkTestFn(op, testSave, .{op.expected});
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

fn checkReload(tasks: []const Task) !void {
    const ops = CheckOpts{ .manual_saves = 1 };
    try checkTestFn(ops, testReload, .{tasks});
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

fn checkAddTask(opts: CheckOpts) !void {
    try checkTestFn(opts, testAddTask, .{ opts.task.?, opts.expected });
}

fn testAddTask(manager: *Manager, task: Task, expected: []const Task) !void {
    const index = try manager.addTask(task);
    const actual = manager.getTask(index);
    try testing.expect(actual != null);
    try util.expectTaskEqual(task, actual.?);
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "get one task with multiple task store" {
    try checkGetOne(.{ .stored = FOUR_TODOS, .index = 1, .task = FOUR_TODOS[1] });
}

test "get one task with single task store" {
    try checkGetOne(.{ .stored = ONE_TODO, .index = 0, .task = ONE_TODO[0] });
}

test "get one with invalid index" {
    try checkGetOne(.{ .stored = ONE_TODO, .index = 1, .task = null });
}

test "get one task with empty store" {
    try checkGetOne(.{ .stored = EMPTY_TASKS, .index = 0, .task = null });
}

fn checkGetOne(opts: CheckOpts) !void {
    var op = opts;
    op.auto_saves = 0;
    try checkTestFn(op, testGetOne, .{ opts.index, opts.task });
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
    try checkMarkDone(.{ .stored = ONE_TODO, .index = 0, .auto_saves = 1 });
}

test "mark done full store of dones" {
    // TODO:
    try checkMarkDone(.{ .stored = FOUR_DONES, .index = 1, .auto_saves = 1 });
}

test "mark done full store of todos" {
    try checkMarkDone(.{ .stored = FOUR_TODOS, .index = 3, .auto_saves = 1 });
}

test "mark done invalid index" {
    try checkMarkDoneError(.{ .stored = ONE_TODO, .index = 1 });
}

test "mark done empty store" {
    try checkMarkDoneError(.{ .stored = EMPTY_TASKS, .index = 0 });
}

fn checkMarkDone(opts: CheckOpts) !void {
    try checkTestFn(opts, testMarkDone, .{opts.index});
}

fn checkMarkDoneError(opts: CheckOpts) !void {
    try checkIndexError(opts, Manager.markDone);
}

fn testMarkDone(manager: *Manager, index: usize) !void {
    const actual = try manager.markDone(index);
    try testMark(manager, index, true, actual);
}

test "unmark done one task" {
    try checkUnmarkDone(.{ .stored = ONE_DONE, .index = 0, .auto_saves = 1 });
}

test "unmark done full store of todos" {
    // TODO:
    try checkUnmarkDone(.{ .stored = FOUR_TODOS, .index = 2, .auto_saves = 1 });
}

test "unmark done full store of dones" {
    try checkUnmarkDone(.{ .stored = FOUR_DONES, .index = 3, .auto_saves = 1 });
}

test "unmark done invalid index" {
    try checkUnmarkDoneError(.{ .stored = ONE_DONE, .index = 1 });
}

test "unmark done empty store" {
    try checkUnmarkDoneError(.{ .stored = EMPTY_TASKS, .index = 0 });
}

fn checkUnmarkDone(opts: CheckOpts) !void {
    try checkTestFn(opts, testUnmarkDone, .{opts.index});
}

fn checkUnmarkDoneError(opts: CheckOpts) !void {
    try checkIndexError(opts, Manager.unmarkDone);
}

fn testUnmarkDone(manager: *Manager, index: usize) !void {
    const actual = try manager.unmarkDone(index);
    try testMark(manager, index, false, actual);
}

test "delete one task" {
    try checkDelete(.{ .stored = ONE_TODO, .index = 0, .expected = EMPTY_TASKS });
}

test "delete invalid index" {
    try checkDeleteError(.{ .stored = ONE_TODO, .index = 1 });
}

test "delete empty store" {
    try checkDeleteError(.{ .stored = EMPTY_TASKS, .index = 0 });
}

test "delete middle task and preserve order" {
    try checkDelete(.{ .stored = FOUR_TODOS, .index = 1, .expected = &.{
        FOUR_TODOS[0],
        FOUR_TODOS[2],
        FOUR_TODOS[3],
    } });
}

fn checkDelete(opts: CheckOpts) !void {
    try checkTestFn(opts, testDelete, .{ opts.expected, opts.index });
}

fn checkDeleteError(opts: CheckOpts) !void {
    try checkIndexError(opts, Manager.delete);
}

fn testDelete(manager: *Manager, expected: []const Task, index: usize) !void {
    try manager.delete(index);
    try util.expectTaskSliceEqual(expected, manager.allTasks());
}

test "set task first" {
    try checkSetFirst(.{ .stored = FOUR_TODOS, .index = 1, .expected = &.{
        FOUR_TODOS[1],
        FOUR_TODOS[0],
        FOUR_TODOS[2],
        FOUR_TODOS[3],
    } });
}

test "set single task first" {
    try checkSetFirst(.{
        .stored = ONE_TODO,
        .index = 0,
        .expected = ONE_TODO,
        .auto_saves = 0,
    });
}

test "set first invalid index" {
    try checkSetFirstError(.{ .stored = ONE_TODO, .index = 1 });
}

test "set first empty store" {
    try checkSetFirstError(.{ .stored = EMPTY_TASKS, .index = 0 });
}

test "set first from end task and preserve order" {
    try checkSetFirst(.{ .stored = FOUR_TODOS, .index = 3, .expected = &.{
        FOUR_TODOS[3],
        FOUR_TODOS[0],
        FOUR_TODOS[1],
        FOUR_TODOS[2],
    } });
}

fn checkSetFirst(opts: CheckOpts) !void {
    try checkTestFn(opts, testSetFirst, .{ opts.expected, opts.index });
}

fn checkSetFirstError(opts: CheckOpts) !void {
    try checkIndexError(opts, Manager.setFirst);
}

fn testSetFirst(manager: *Manager, expected: []const Task, index: usize) !void {
    try manager.setFirst(index);
    const actual = manager.allTasks();
    try util.expectTaskSliceEqual(expected, actual);
}

test "delete all done empty store" {
    try checkDeleteAllDone(.{ .stored = EMPTY_TASKS, .auto_saves = 0 });
}

test "delete all done with only dones" {
    try checkDeleteAllDone(.{ .stored = FOUR_DONES, .auto_saves = 1 });
}

test "delete all done with only todos" {
    try checkDeleteAllDone(.{ .stored = FOUR_TODOS, .auto_saves = 0 });
}

test "delete all done with todos and dones" {
    try checkDeleteAllDone(.{ .stored = FOUR_MIXED, .auto_saves = 1 });
}

fn checkDeleteAllDone(opts: CheckOpts) !void {
    try checkTestFn(opts, testDeleteAllDone, .{});
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

fn checkTestFn(opts: CheckOpts, test_fn: anytype, args: anytype) !void {
    var tester = ManagerTester(test_fn){
        .tasks = opts.stored,
        .auto_saves = opts.auto_saves,
        .manual_saves = opts.manual_saves,
    };
    try tester.call(args);
}

fn checkIndexError(opts: CheckOpts, method: anytype) !void {
    try checkErrorTestFn(opts, testIndexError, .{ method, opts.index });
}

fn checkErrorTestFn(opts: CheckOpts, test_fn: anytype, args: anytype) !void {
    var op = opts;
    op.auto_saves = 0;
    try checkTestFn(op, test_fn, args);
}

const CheckOpts = struct {
    stored: []const Task = EMPTY_TASKS,
    expected: []const Task = EMPTY_TASKS,
    task: ?Task = null,
    index: usize = 0,
    auto_saves: usize = 1,
    manual_saves: usize = 0,
};

/// Create a testing environment for a `Manager`.
fn ManagerTester(test_fn: anytype) type {
    return struct {
        /// Tasks to put in the manager's store.
        tasks: []const Task,
        /// Expected number of writes to the store.
        auto_saves: usize,
        manual_saves: usize = 0,
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
            try testing.expectEqual(self.auto_saves, store.saved);
        }

        pub fn callManual(self: *Self, args: anytype) !void {
            var store = util.TestStore.init(self.tasks);
            var manager = try Manager.initManualSave(allocator, store.taskStore());
            defer manager.deinit();
            try @call(.auto, test_fn, .{&manager} ++ args);
            try testing.expectEqual(self.manual_saves, store.saved);
        }
    };
}
