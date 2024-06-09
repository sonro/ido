const std = @import("std");
const ido = @import("ido.zig");

pub const Manager = struct {
    allocator: std.mem.Allocator,
    store: ido.TaskStore,
    tasks: std.ArrayList(ido.Task),

    pub fn init(allocator: std.mem.Allocator, store: ido.TaskStore) !Manager {
        var task_store = store;
        const tasks = try task_store.load(allocator);
        return Manager{
            .allocator = allocator,
            .store = task_store,
            .tasks = tasks,
        };
    }

    pub fn deinit(self: *const Manager) void {
        self.tasks.deinit();
    }

    pub fn allTasks(self: *const Manager) []const ido.Task {
        return self.tasks.items;
    }
};
