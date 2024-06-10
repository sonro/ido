const std = @import("std");
const ido = @import("ido.zig");

pub const Error = error{
    NoTaskName,
};

pub const Task = struct {
    name: []const u8,
    description: ?[]const u8,
    done: bool,

    pub fn new(name: []const u8, description: []const u8) Error!Task {
        return rawNew(name, description, false);
    }

    pub fn newSimple(name: []const u8) Error!Task {
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

    fn rawNew(name: []const u8, description: ?[]const u8, done: bool) Error!Task {
        var task = Task{
            .name = name,
            .description = description,
            .done = done,
        };
        try validate(&task);
        return task;
    }
};

pub fn validate(task: *Task) Error!void {
    try validateName(task.name);
    if (task.description) |desc| {
        if (desc.len == 0) task.description = null;
    }
}

fn validateName(name: []const u8) Error!void {
    if (name.len == 0) return Error.NoTaskName;
}
