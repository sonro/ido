const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");
const Task = ido.Task;
const Error = ido.Error;
const checkTaskNotDone = util.checkTaskNotDone;
const checkTaskDone = util.checkTaskDone;

test "create with anon struct" {
    const task = .{ .name = "anon", .description = "some", .done = true };
    try checkTaskDone(task, "anon", "some");
}

test "create with anon struct only name" {
    const task = .{ .name = "anon" };
    try checkTaskNotDone(task, "anon", null);
}

test "create new simple task" {
    const task = try Task.newSimple("a");
    try checkTaskNotDone(task, "a", null);
}

test "create new simple task with empty name" {
    const res = Task.newSimple("");
    try testing.expectError(Error.NoTaskName, res);
}

test "create new task with description" {
    const task = try Task.new("a", "b");
    try checkTaskNotDone(task, "a", "b");
}

test "create new task with empty name" {
    const res = Task.new("", "b");
    try testing.expectError(Error.NoTaskName, res);
}

test "create new task with empty description" {
    const task = try Task.new("a", "");
    try checkTaskNotDone(task, "a", null);
}

test "create new task with empty name and description" {
    const res = Task.new("", "");
    try testing.expectError(Error.NoTaskName, res);
}

test "mark task as done" {
    var task = try Task.new("a", "b");
    task.done = true;
    try checkTaskDone(task, "a", "b");
}

test "format simple task" {
    const task = try Task.newSimple("a");
    const expected = try createFormatString("a", null, false);
    defer allocator.free(expected);
    try checkTaskFmt(expected, task);
}

test "format simple done task" {
    var task = try Task.newSimple("a");
    task.done = true;
    const expected = try createFormatString("a", null, true);
    defer allocator.free(expected);
    try checkTaskFmt(expected, task);
}

test "format task with description" {
    const task = try Task.new("a", "b");
    const expected = try createFormatString("a", "b", false);
    defer allocator.free(expected);
    try checkTaskFmt(expected, task);
}

test "format task with description and done" {
    var task = try Task.new("a", "b");
    task.done = true;
    const expected = try createFormatString("a", "b", true);
    defer allocator.free(expected);
    try checkTaskFmt(expected, task);
}

fn createFormatString(
    name: []const u8,
    description: ?[]const u8,
    done: bool,
) ![]const u8 {
    var string = std.ArrayList(u8).init(allocator);
    try string.writer().print(
        \\Task.{{
        \\    .name = "{s}",
        \\    .description = "{s}",
        \\    .done = {s},
        \\}}
    , .{
        name,
        if (description) |desc| desc else "",
        if (done) "true" else "false",
    });

    return string.toOwnedSlice();
}

fn checkTaskFmt(expected: []const u8, task: Task) !void {
    var buf = [_]u8{0} ** 100;
    const formatted = try std.fmt.bufPrint(&buf, "{}", .{task});
    try testing.expectEqualStrings(expected, formatted);
}
