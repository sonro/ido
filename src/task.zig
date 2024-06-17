const std = @import("std");
const ido = @import("ido.zig");

pub const Error = error{
    NoTaskName,
};

pub const Task = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    done: bool = false,

    pub fn new(name: []const u8, description: []const u8) Error!Task {
        return rawNew(name, description, false);
    }

    pub fn newSimple(name: []const u8) Error!Task {
        return rawNew(name, null, false);
    }

    pub fn format(self: Task, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print(
            \\Task.{{
            \\    .name = "{s}",
            \\    .description = "{s}",
            \\    .done = {s},
            \\}}
        , .{
            self.name,
            self.description orelse "",
            if (self.done) "true" else "false",
        });
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
