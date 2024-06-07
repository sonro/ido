const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;
const TODO_PATTERN = ido.TODO_PATTERN;
const DONE_PATTERN = ido.DONE_PATTERN;

pub const ParseError = error{
    NoTaskName,
};

pub fn parseTask(input: []const u8) ParseError!Task {
    var task = Task{ .name = undefined, .description = null, .done = undefined };
    const start = findTaskStart(input);
    const end = findTaskEnd(input, start);

    setTaskDone(&task, input[0..start]);
    parseTaskData(&task, input[start..end]);
    trimTaskData(&task);
    try task.validate();

    return task;
}

fn findTaskStart(input: []const u8) usize {
    var start: usize = 0;
    if (std.mem.indexOf(u8, input, TODO_PATTERN)) |index| {
        start = index + TODO_PATTERN.len;
    } else if (std.mem.indexOf(u8, input, DONE_PATTERN)) |index| {
        start = index + DONE_PATTERN.len;
    }
    return start;
}

fn setTaskDone(task: *Task, input: []const u8) void {
    task.done = std.mem.indexOf(u8, input, DONE_PATTERN) != null;
}

fn findTaskEnd(input: []const u8, start: usize) usize {
    const end = std.mem.indexOf(u8, input[start..], "\n\n") orelse
        std.mem.indexOf(u8, input[start..], TODO_PATTERN) orelse
        std.mem.indexOf(u8, input[start..], DONE_PATTERN);

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
    task.name = std.mem.trim(u8, task.name, " \t");
    if (task.description) |d| {
        task.description = std.mem.trim(u8, d, " \t");
        if (task.description.?.len == 0) {
            task.description = null;
        }
    }
}
