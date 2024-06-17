//! CSV format for tests
const std = @import("std");
const ido = @import("ido");
const Task = ido.Task;

pub const TODO_PATTERN = "";
pub const DONE_PATTERN = "done";

pub fn serializeTaskList(tasks: []const Task, writer: anytype) !void {
    for (tasks) |task| {
        try serializeTask(task, writer);
    }
}

pub fn serializeTask(task: Task, writer: anytype) !void {
    try writer.print("{s},{s},{s}\n", .{
        task.name,
        if (task.description) |desc| desc else "",
        if (task.done) DONE_PATTERN else TODO_PATTERN,
    });
}

pub fn parseTaskList(
    tasklist: *std.ArrayList(Task),
    input: []const u8,
) !void {
    // split by newlines
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try tasklist.append(try parseTask(line));
    }
}

pub fn parseTask(input: []const u8) !Task {
    var task = Task{ .name = undefined, .description = null, .done = undefined };

    // split by commas
    var fields = std.mem.splitScalar(u8, input, ',');
    task.name = fields.first();
    if (fields.next()) |desc| {
        task.description = desc;
    } else {
        return error.InvalidFormat;
    }
    if (fields.next()) |done| {
        if (std.mem.eql(u8, done, DONE_PATTERN)) task.done = true;
    } else {
        return error.InvalidFormat;
    }

    trimTaskData(&task);
    try ido.task.validate(&task);

    return task;
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
