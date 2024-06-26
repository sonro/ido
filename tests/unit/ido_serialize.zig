const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("test-util");
const Task = ido.Task;
const Format = ido.Format;

const TODO_PREFIX = "TODO: ";
const DONE_PREFIX = "DONE: ";
const DESC_SEPARATOR = "\n";
const TASK_SUFFIX = "\n\n";

test "tasklist empty" {
    try checkList(&.{});
}

test "tasklist single task" {
    try checkList(&.{
        .{ .name = "foo" },
    });
}

test "tasklist multiple tasks" {
    try checkList(&.{
        .{
            .name = "foo",
        },
        .{ .name = "bar", .done = true },
    });
}

test "simple task" {
    try checkTask(.{ .name = "foo" });
}

test "simple done task" {
    try checkTask(.{ .name = "foo", .done = true });
}

test "task with description" {
    try checkTask(.{ .name = "foo", .description = "bar" });
}

test "task with description containing newline" {
    try checkTask(.{ .name = "foo", .description = "bar\nbaz" });
}

test "done task with description" {
    try checkTask(.{ .name = "foo", .description = "bar", .done = true });
}

fn checkTask(comptime task: Task) !void {
    const expected = expectedTaskString(task);
    try testSerializeTask(expected, task);
}

fn checkList(comptime tasks: []const ido.Task) !void {
    const expected = try expectedListString(tasks);
    defer expected.deinit();
    try testSerializeTaskList(expected.items, tasks);
}

fn expectedTaskString(comptime task: ido.Task) []const u8 {
    if (task.done and task.description == null) {
        return expectedDoneSimple(task.name);
    } else if (task.done) {
        return expectedDone(task.name, task.description.?);
    } else if (task.description == null) {
        return expectedTodoSimple(task.name);
    } else {
        return expectedTodo(task.name, task.description.?);
    }
}

fn expectedListString(comptime tasks: []const Task) !std.ArrayList(u8) {
    var string = std.ArrayList(u8).init(allocator);
    inline for (tasks) |task| {
        try string.appendSlice(expectedTaskString(task));
    }
    return string;
}

fn testSerializeTask(expected: []const u8, task: Task) !void {
    try testSerializeFn(expected, Format.serializeTask, task);
}

fn testSerializeTaskList(expected: []const u8, tasks: []const Task) !void {
    try testSerializeFn(expected, Format.serializeTaskList, tasks);
}

fn testSerializeFn(expected: []const u8, testFn: anytype, taskArg: anytype) !void {
    var actual = try std.ArrayList(u8).initCapacity(allocator, expected.len);
    defer actual.deinit();
    try testFn(taskArg, actual.writer());
    try testing.expectEqualStrings(expected, actual.items);
}

fn expectedTodoSimple(comptime name: []const u8) []const u8 {
    return TODO_PREFIX ++ name ++ TASK_SUFFIX;
}

fn expectedDoneSimple(comptime name: []const u8) []const u8 {
    return DONE_PREFIX ++ name ++ TASK_SUFFIX;
}

fn expectedTodo(comptime name: []const u8, comptime desc: []const u8) []const u8 {
    return TODO_PREFIX ++ name ++ DESC_SEPARATOR ++ desc ++ TASK_SUFFIX;
}

fn expectedDone(comptime name: []const u8, comptime desc: []const u8) []const u8 {
    return DONE_PREFIX ++ name ++ DESC_SEPARATOR ++ desc ++ TASK_SUFFIX;
}
