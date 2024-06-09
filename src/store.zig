const std = @import("std");
const ido = @import("ido.zig");

/// Interface for saving and loading tasks
pub const TaskStore = struct {
    /// Type erased pointer to the underlying implmentation
    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn save(self: *TaskStore, tasks: []const ido.Task) !void {
        return self.vtable.save(self.ptr, tasks);
    }

    pub fn load(self: *TaskStore, allocator: std.mem.Allocator) !std.ArrayList(ido.Task) {
        return self.vtable.load(self.ptr, allocator);
    }
};

pub const VTable = struct {
    save: *const fn (*anyopaque, []const ido.Task) anyerror!void,
    load: *const fn (*anyopaque, std.mem.Allocator) anyerror!std.ArrayList(ido.Task),
};
