const std = @import("std");
const ido = @import("ido.zig");
const Task = ido.Task;
const TODO_PATTERN = ido.TODO_PATTERN;
const DONE_PATTERN = ido.DONE_PATTERN;

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
