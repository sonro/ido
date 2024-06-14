const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");
const checkTaskNotDone = util.checkTaskNotDone;
const checkTaskDone = util.checkTaskDone;

test "create new simple task" {
    const task = try ido.Task.newSimple("a");
    try checkTaskNotDone(task, "a", null);
}

test "create new simple task with empty name" {
    const res = ido.Task.newSimple("");
    try testing.expectError(ido.task.Error.NoTaskName, res);
}

test "create new task with description" {
    const task = try ido.Task.new("a", "b");
    try checkTaskNotDone(task, "a", "b");
}

test "create new task with empty name" {
    const res = ido.Task.new("", "b");
    try testing.expectError(ido.task.Error.NoTaskName, res);
}

test "create new task with empty description" {
    const task = try ido.Task.new("a", "");
    try checkTaskNotDone(task, "a", null);
}

test "create new task with empty name and description" {
    const res = ido.Task.new("", "");
    try testing.expectError(ido.task.Error.NoTaskName, res);
}

test "mark task as done" {
    var task = try ido.Task.new("a", "b");
    task.done = true;
    try checkTaskDone(task, "a", "b");
}

test "format simple task" {
    const task = try ido.Task.newSimple("a");
    try checkTaskFmt("TODO: a", task);
}

test "format simple done task" {
    var task = try ido.Task.newSimple("a");
    task.done = true;
    try checkTaskFmt("DONE: a", task);
}

test "format task with description" {
    const task = try ido.Task.new("a", "b");
    try checkTaskFmt("TODO: a\nb", task);
}

test "format task with description and done" {
    var task = try ido.Task.new("a", "b");
    task.done = true;
    try checkTaskFmt("DONE: a\nb", task);
}

fn checkTaskFmt(comptime expected: []const u8, task: ido.Task) !void {
    var buf = [_]u8{0} ** expected.len;
    const formatted = try std.fmt.bufPrint(&buf, "{}", .{task});
    try testing.expectEqualStrings(expected, formatted);
}
