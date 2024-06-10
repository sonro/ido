const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;
const ido = @import("ido");
const util = @import("util.zig");

const TODO_PREFIX = "TODO: ";
const DONE_PREFIX = "DONE: ";
const DESC_SEPARATOR = "\n";
const TASK_SUFFIX = "\n\n";

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

fn checkDone(comptime name: []const u8, comptime desc: []const u8) !void {
    var task = try ido.Task.new(name, desc);
    task.done = true;
    const expected = comptime expectedDone(name, desc);
    try checkSerializeTask(expected, task);
}

fn checkSerializeTask(comptime expected: []const u8, task: ido.Task) !void {
    var string = try std.ArrayList(u8).initCapacity(allocator, expected.len);
    defer string.deinit();
    try ido.format.serializeTask(task, string.writer());
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
