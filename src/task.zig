const std = @import("std");
const ido = @import("ido.zig");

pub const TaskError = error{
    NoTaskName,
};

pub const Task = struct {
    name: []const u8,
    description: ?[]const u8,
    done: bool,

    pub fn new(name: []const u8, description: []const u8) TaskError!Task {
        return rawNew(name, description, false);
    }

    pub fn newSimple(name: []const u8) TaskError!Task {
        return rawNew(name, null, false);
    }

    pub fn format(self: Task, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (self.done) {
            try writer.writeAll(ido.DONE_PATTERN);
        } else {
            try writer.writeAll(ido.TODO_PATTERN);
        }
        try writer.print(" {s}", .{self.name});
        if (self.description) |desc| {
            try writer.print("\n{s}", .{desc});
        }
    }

    pub fn validate(self: *Task) TaskError!void {
        try validateName(self.name);
        if (self.description) |desc| {
            if (desc.len == 0) self.description = null;
        }
    }

    fn rawNew(name: []const u8, description: ?[]const u8, done: bool) TaskError!Task {
        var task = Task{
            .name = name,
            .description = description,
            .done = done,
        };
        try task.validate();
        return task;
    }
};

fn validateName(name: []const u8) TaskError!void {
    if (name.len == 0) return TaskError.NoTaskName;
}
