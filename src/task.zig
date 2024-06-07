const std = @import("std");

pub const TaskError = error{
    NoTaskName,
};

pub const Task = struct {
    name: []const u8,
    description: ?[]const u8,

    pub fn new(name: []const u8, description: []const u8) TaskError!Task {
        return rawNew(name, description);
    }

    pub fn newSimple(name: []const u8) TaskError!Task {
        return rawNew(name, null);
    }

    fn rawNew(name: []const u8, description: ?[]const u8) TaskError!Task {
        var task = Task{
            .name = name,
            .description = description,
        };
        try task.validate();
        return task;
    }

    fn validate(self: *Task) TaskError!void {
        try validateName(self.name);
        if (self.description) |desc| {
            if (desc.len == 0) self.description = null;
        }
    }
};

fn validateName(name: []const u8) TaskError!void {
    if (name.len == 0) return TaskError.NoTaskName;
}
