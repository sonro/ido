const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("util.zig");
const checkTaskNotDone = util.checkTaskNotDone;
const checkTaskDone = util.checkTaskDone;
const ParseError = ido.ParseError;

test "tasklist from empty string" {
    try checkTaskList(&.{}, "");
}

test "tasklist from single task" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = null, .done = false },
    }, "TODO: foo");
}

test "tasklist from multiple tasks" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = null, .done = false },
        .{ .name = "bar", .description = null, .done = true },
    }, "TODO: foo\nDONE: bar");
}

test "tasklist from multiple tasks using blank lines" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = null, .done = false },
        .{ .name = "bar", .description = null, .done = true },
    }, "\n\nTODO: foo\n\nDONE: bar\n\n");
}

test "tasklist from single task with description" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = "bar", .done = false },
    }, "TODO: foo\nbar");
}

test "tasklist from multiple tasks with description" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = "bar", .done = false },
        .{ .name = "bar", .description = "baz", .done = true },
    }, "TODO: foo\nbar\nDONE: bar\nbaz");
}

test "simple task" {
    const task = try ido.parseTask("TODO: foo");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task no whitespace" {
    const task = try ido.parseTask("TODO:foo");
    try checkTaskNotDone(task, "foo", null);
}

test "simple done task" {
    const task = try ido.parseTask("DONE: foo");
    try checkTaskDone(task, "foo", null);
}

test "simple done task no whitespace" {
    const task = try ido.parseTask("DONE:foo");
    try checkTaskDone(task, "foo", null);
}

test "simple task with newline ending" {
    const task = try ido.parseTask("TODO: foo\n");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task with blank line ending" {
    const task = try ido.parseTask("TODO: foo\n\n");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task todo ending" {
    const task = try ido.parseTask("TODO: foo TODO: bar");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task todo ending no whitespace" {
    const task = try ido.parseTask("TODO:fooTODO:bar");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task done ending" {
    const task = try ido.parseTask("DONE: foo DONE: bar");
    try checkTaskDone(task, "foo", null);
}

test "simple task done ending no whitespace" {
    const task = try ido.parseTask("DONE:fooDONE:bar");
    try checkTaskDone(task, "foo", null);
}

test "task with description" {
    const task = try ido.parseTask("TODO: foo\nbar");
    try checkTaskNotDone(task, "foo", "bar");
}

test "task with description containing newline" {
    const task = try ido.parseTask("TODO: foo\nbar\nbaz");
    try checkTaskNotDone(task, "foo", "bar\nbaz");
}

test "task with description containing blank line" {
    const task = try ido.parseTask("TODO: foo\nbar\n\nbaz");
    try checkTaskNotDone(task, "foo", "bar");
}

test "task with whitespace only description" {
    const task = try ido.parseTask("TODO: foo\n   ");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task no name error" {
    const res = ido.parseTask("TODO: ");
    try testing.expectError(ParseError.NoTaskName, res);
}

test "task with description no name error" {
    const res = ido.parseTask("TODO: \nbar");
    try testing.expectError(ParseError.NoTaskName, res);
}

test "whitespace before simple task" {
    const task = try ido.parseTask("  TODO: foo");
    try checkTaskNotDone(task, "foo", null);
}

test "newline before simple task" {
    const task = try ido.parseTask("\nTODO: foo");
    try checkTaskNotDone(task, "foo", null);
}

test "whitespace before simple done task" {
    const task = try ido.parseTask("  DONE: foo");
    try checkTaskDone(task, "foo", null);
}

test "newline before simple done task" {
    const task = try ido.parseTask("\nDONE: foo");
    try checkTaskDone(task, "foo", null);
}

test "simple task no TODO" {
    const task = try ido.parseTask("foo");
    try checkTaskNotDone(task, "foo", null);
}

test "task with description no TODO" {
    const task = try ido.parseTask("foo\nbar");
    try checkTaskNotDone(task, "foo", "bar");
}

fn checkTaskList(comptime expected: []const ido.Task, comptime input: []const u8) !void {
    const tasklist = try ido.parseTaskList(allocator, input);
    defer tasklist.deinit();
    try testing.expectEqual(expected.len, tasklist.items.len);
    for (expected, tasklist.items) |exp, act| {
        try util.expectTaskEqual(exp, act);
    }
}
