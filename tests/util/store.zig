const std = @import("std");
const testing = std.testing;
const ido = @import("ido");

pub const TestStore = struct {
    allocator: std.mem.Allocator = testing.allocator,
    tasks: []const ido.Task = &.{},
    saved: u32 = 0,

    pub fn init(tasks: []const ido.Task) TestStore {
        return .{ .tasks = tasks };
    }

    pub fn taskStore(self: *TestStore) ido.TaskStore {
        return ido.TaskStore.interface(self);
    }

    pub fn save(self: *TestStore, tasks: []const ido.Task) !void {
        self.tasks = tasks;
        self.saved += 1;
    }

    pub fn load(
        self: *const TestStore,
        allocator: std.mem.Allocator,
    ) !std.ArrayList(ido.Task) {
        var tasklist = try std.ArrayList(ido.Task).initCapacity(allocator, self.tasks.len);
        tasklist.appendSliceAssumeCapacity(self.tasks);
        return tasklist;
    }

    pub fn loadInto(self: *const TestStore, allocator: std.mem.Allocator, tasklist: *std.ArrayList(ido.Task)) !void {
        try tasklist.appendSlice(allocator, self.tasks);
    }
};
