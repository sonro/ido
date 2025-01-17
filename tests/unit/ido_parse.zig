const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const fixtures = @import("fixtures");
const util = @import("test-util");
const Format = ido.Format;
const Task = ido.Task;
const expected_mixed = fixtures.simple.tasks;
const mixed_ido_content = fixtures.simple.ido_content;
const checkTaskNotDone = util.checkTaskNotDone;
const checkTaskDone = util.checkTaskDone;

test "tasklist from empty string" {
    try checkTaskList(&.{}, "");
}

test "tasklist from single task" {
    try checkTaskList(
        &.{
            .{ .name = "foo" },
        },
        "TODO: foo",
    );
}

test "tasklist from multiple tasks" {
    try checkTaskList(
        &.{
            .{ .name = "foo" },
            .{ .name = "bar", .done = true },
        },
        "TODO: foo\nDONE: bar",
    );
}

test "tasklist from multiple tasks using blank lines" {
    try checkTaskList(
        &.{
            .{ .name = "foo" },
            .{ .name = "bar", .done = true },
        },
        "\n\nTODO: foo\n\nDONE: bar\n\n",
    );
}

test "tasklist from single task with description" {
    try checkTaskList(
        &.{
            .{ .name = "foo", .description = "bar" },
        },
        "TODO: foo\nbar",
    );
}

test "tasklist from multiple tasks with description" {
    try checkTaskList(
        &.{
            .{ .name = "foo", .description = "bar" },
            .{ .name = "bar", .description = "baz", .done = true },
        },
        "TODO: foo\nbar\nDONE: bar\nbaz",
    );
}

test "long mixed tasklist" {
    try checkTaskList(
        &expected_mixed,
        mixed_ido_content,
    );
}

test "simple task" {
    const task = try Format.parseTask("TODO: foo");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task no whitespace" {
    const task = try Format.parseTask("TODO:foo");
    try checkTaskNotDone(task, "foo", null);
}

test "simple done task" {
    const task = try Format.parseTask("DONE: foo");
    try checkTaskDone(task, "foo", null);
}

test "simple done task no whitespace" {
    const task = try Format.parseTask("DONE:foo");
    try checkTaskDone(task, "foo", null);
}

test "simple task with newline ending" {
    const task = try Format.parseTask("TODO: foo\n");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task with blank line ending" {
    const task = try Format.parseTask("TODO: foo\n\n");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task todo ending" {
    const task = try Format.parseTask("TODO: foo TODO: bar");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task todo ending no whitespace" {
    const task = try Format.parseTask("TODO:fooTODO:bar");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task done ending" {
    const task = try Format.parseTask("DONE: foo DONE: bar");
    try checkTaskDone(task, "foo", null);
}

test "simple task done ending no whitespace" {
    const task = try Format.parseTask("DONE:fooDONE:bar");
    try checkTaskDone(task, "foo", null);
}

test "task with description" {
    const task = try Format.parseTask("TODO: foo\nbar");
    try checkTaskNotDone(task, "foo", "bar");
}

test "task with description containing newline" {
    const task = try Format.parseTask("TODO: foo\nbar\nbaz");
    try checkTaskNotDone(task, "foo", "bar\nbaz");
}

test "task with description containing blank line" {
    const task = try Format.parseTask("TODO: foo\nbar\n\nbaz");
    try checkTaskNotDone(task, "foo", "bar");
}

test "task with whitespace only description" {
    const task = try Format.parseTask("TODO: foo\n   ");
    try checkTaskNotDone(task, "foo", null);
}

test "simple task no name error" {
    const res = Format.parseTask("TODO: ");
    try testing.expectError(error.NoTaskName, res);
}

test "task with description no name error" {
    const res = Format.parseTask("TODO: \nbar");
    try testing.expectError(error.NoTaskName, res);
}

test "whitespace before simple task" {
    const task = try Format.parseTask("  TODO: foo");
    try checkTaskNotDone(task, "foo", null);
}

test "newline before simple task" {
    const task = try Format.parseTask("\nTODO: foo");
    try checkTaskNotDone(task, "foo", null);
}

test "whitespace before simple done task" {
    const task = try Format.parseTask("  DONE: foo");
    try checkTaskDone(task, "foo", null);
}

test "newline before simple done task" {
    const task = try Format.parseTask("\nDONE: foo");
    try checkTaskDone(task, "foo", null);
}

test "no task error" {
    const res = Format.parseTask("foo");
    try testing.expectError(error.NoTask, res);
}

fn checkTaskList(comptime expected: []const Task, comptime input: []const u8) !void {
    var tasklist = try std.ArrayList(Task).initCapacity(allocator, expected.len);
    try Format.parseTaskList(&tasklist, input);
    defer tasklist.deinit();
    try util.expectTaskSliceEqual(expected, tasklist.items);
}
