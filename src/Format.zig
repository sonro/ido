//! Ido format module
//!
//! A simple text-based format for tasks:
//! ```txt
//! TODO: task name
//!
//! DONE: another task name
//! optional description
//! ```
const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;
const TODO_PATTERN = ido.TODO_PATTERN;
const DONE_PATTERN = ido.DONE_PATTERN;

pub fn serializeTaskList(tasks: []const Task, writer: anytype) !void {
    for (tasks) |task| {
        try serializeTask(task, writer);
    }
}

pub fn serializeTask(task: Task, writer: anytype) !void {
    try writer.print("{s} {s}\n", .{
        if (task.done) DONE_PATTERN else TODO_PATTERN,
        task.name,
    });

    if (task.description) |desc| {
        try writer.print("{s}\n", .{desc});
    }
    try writer.writeByte('\n');
}

pub fn parseTaskList(
    allocator: std.mem.Allocator,
    input: []const u8,
) !std.ArrayList(Task) {
    var tasklist = std.ArrayList(Task).init(allocator);
    errdefer tasklist.deinit();
    var start: usize = 0;
    while (findNextTask(input[start..])) |index| {
        start += index;
        const task = try parseTask(input[start..]);
        try tasklist.append(task);
        start += task.name.len;
        if (task.description) |desc| {
            start += desc.len;
        }
        if (start >= input.len) {
            break;
        }
    }

    return tasklist;
}

pub fn parseTask(input: []const u8) !Task {
    var task = Task{ .name = undefined, .description = null, .done = undefined };
    const start = findTaskStart(input) orelse return error.NoTask;
    const end = findTaskEnd(input, start);

    setTaskDone(&task, input[0..start]);
    parseTaskData(&task, input[start..end]);
    trimTaskData(&task);
    try ido.task.validate(&task);

    return task;
}

fn findNextTask(input: []const u8) ?usize {
    return std.mem.indexOf(u8, input, TODO_PATTERN) orelse
        std.mem.indexOf(u8, input, DONE_PATTERN);
}

fn findTaskStart(input: []const u8) ?usize {
    if (std.mem.indexOf(u8, input, TODO_PATTERN)) |index| {
        return index + TODO_PATTERN.len;
    } else if (std.mem.indexOf(u8, input, DONE_PATTERN)) |index| {
        return index + DONE_PATTERN.len;
    }
    return null;
}

fn setTaskDone(task: *Task, input: []const u8) void {
    task.done = std.mem.indexOf(u8, input, DONE_PATTERN) != null;
}

fn findTaskEnd(input: []const u8, start: usize) usize {
    const end =
        std.mem.indexOf(u8, input[start..], TODO_PATTERN) orelse
        std.mem.indexOf(u8, input[start..], DONE_PATTERN) orelse
        std.mem.indexOf(u8, input[start..], "\n\n");

    return if (end) |e| e + start else input.len;
}

fn parseTaskData(task: *Task, input: []const u8) void {
    if (std.mem.indexOf(u8, input, "\n")) |index| {
        task.name = input[0..index];
        // check for description
        if (index + 2 < input.len) {
            task.description = input[index + 1 ..];
        }
    } else {
        task.name = input;
    }
}

fn trimTaskData(task: *Task) void {
    task.name = std.mem.trim(u8, task.name, " \t\r\n");
    if (task.description) |d| {
        task.description = std.mem.trim(u8, d, " \t\r\n");
        if (task.description.?.len == 0) {
            task.description = null;
        }
    }
}
