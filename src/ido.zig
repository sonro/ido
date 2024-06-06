const std = @import("std");

pub const Task = struct {
    name: []const u8,
    description: ?[]const u8,

    pub fn simple(name: []const u8) Task {
        return Task{
            .name = name,
            .description = null,
        };
    }
};
