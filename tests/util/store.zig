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
        return ido.TaskStore.init(self);
    }

    pub fn save(self: *TestStore, tasks: []const ido.Task) !void {
        self.tasks = tasks;
        self.saved += 1;
    }

    pub fn load(
        self: *TestStore,
        allocator: std.mem.Allocator,
    ) !std.ArrayList(ido.Task) {
        var tasklist = std.ArrayList(ido.Task).init(allocator);
        try tasklist.appendSlice(self.tasks);
        return tasklist;
    }
};
