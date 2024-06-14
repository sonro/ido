const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const Format = ido.Format;
const util = @import("test-util");

const TODO_PREFIX = "TODO: ";
const DONE_PREFIX = "DONE: ";
const DESC_SEPARATOR = "\n";
const TASK_SUFFIX = "\n\n";

test "tasklist empty" {
    try checkTaskList(&.{});
}

test "tasklist single task" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = null, .done = false },
    });
}

test "tasklist multiple tasks" {
    try checkTaskList(&.{
        .{ .name = "foo", .description = null, .done = false },
        .{ .name = "bar", .description = null, .done = true },
    });
}

test "simple task" {
    try checkTodoSimple("foo");
}

test "simple done task" {
    try checkDoneSimple("foo");
}

test "task with description" {
    try checkTodo("foo", "bar");
}

test "task with description containing newline" {
    try checkTodo("foo", "bar\nbaz");
}

test "done task with description" {
    try checkDone("foo", "bar");
}

fn checkTodoSimple(comptime name: []const u8) !void {
    const task = try ido.Task.newSimple(name);
    const expected = comptime expectedTodoSimple(name);
    try checkSerializeTask(expected, task);
}

fn checkTodo(comptime name: []const u8, comptime desc: []const u8) !void {
    const task = try ido.Task.new(name, desc);
    const expected = comptime expectedTodo(name, desc);
    try checkSerializeTask(expected, task);
}

fn checkDoneSimple(comptime name: []const u8) !void {
    var task = try ido.Task.newSimple(name);
    task.done = true;
    const expected = comptime expectedDoneSimple(name);
    try checkSerializeTask(expected, task);
}

fn checkTaskList(comptime tasks: []const ido.Task) !void {
    const expected = try expectedListString(tasks);
    defer expected.deinit();
    var string = try std.ArrayList(u8).initCapacity(allocator, expected.items.len);
    defer string.deinit();
    try Format.serializeTaskList(tasks, string.writer());
    try testing.expectEqualStrings(expected.items, string.items);
}

fn expectedListString(comptime tasks: []const ido.Task) !std.ArrayList(u8) {
    var string = std.ArrayList(u8).init(allocator);
    inline for (tasks) |task| {
        try string.appendSlice(expectedTask(task));
    }
    return string;
}

fn expectedTask(comptime task: ido.Task) []const u8 {
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

fn checkDone(comptime name: []const u8, comptime desc: []const u8) !void {
    var task = try ido.Task.new(name, desc);
    task.done = true;
    const expected = comptime expectedDone(name, desc);
    try checkSerializeTask(expected, task);
}

fn checkSerializeTask(comptime expected: []const u8, task: ido.Task) !void {
    var string = try std.ArrayList(u8).initCapacity(allocator, expected.len);
    defer string.deinit();
    try Format.serializeTask(task, string.writer());
    try testing.expectEqualStrings(expected, string.items);
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
